import typing as t
from logging import getLogger
import requests
from urllib.request import urlretrieve
import os.path
from zipfile import ZipFile
import lxml.etree as ET

from .utils import MongoDbClient, get_name_file, del_file, prefix_file, tag_name_file, convert_value, join_corp_house_analitic
from .constants import url_all, XML_TMP_FOLDER, ZIP_TMP_FOLDER, FIELD_INSERT_DELTA, LINK_FILE, FILE_SAVE_NAME
from .model import JournalLoadExtractFile, JournalProcessingFiles, JournalFiles
import datetime


logger = getLogger('controls')


class BaseControl(object):
    def __new__(cls, *args, **kwargs):
        cls.logger = logger.getChild(cls.__name__)
        return super().__new__(cls, *args, **kwargs)


class Control(BaseControl):

    def __init__(self):
        self.mongo = MongoControl()
        self.services = GarServices()
        self.unzip = UnZIPFile()

    def control(self):
        is_full = 0
        """Проверка на существование необходимых папок. При отсутствии, их создание"""
        if not self.isdir():
            return 0

        """Определяем последнюю версию данных из монго"""
        version_current = self.mongo.get_current_version_files()
        self.logger.info(f"Версия из монго = {version_current}")

        if version_current is None:
            """Полная загрузка"""
            is_full = 1
            version_list_gar = self.services.versions_down_full()
            link_file = LINK_FILE['full']
            file_name = FILE_SAVE_NAME['full']
        else:
            """Загрузка дельты"""
            version_list_gar = self.services.versions_down(version_current)
            link_file = LINK_FILE['delta']
            file_name = FILE_SAVE_NAME['delta']

        """Закачка файлов на диск"""
        for ver in version_list_gar:
            err = 0
            result = False
            while err <= 5 and not result:
                if self.processing(ver, link_file, file_name) == 0:
                    err += 1
                    if err == 5:
                        self.logger.warning("Загрузка остановлена")
                        break
                else:
                    result = True

        """Загрузка файлов в монгу"""
        mongo_list = self.mongo.get_list_version_for_load()
        if mongo_list is not None:
            [self.processing_loads(model, XML_TMP_FOLDER, is_full) for model in mongo_list]

        return 0

    def isdir(self):
        """Проверка на существование папок. Если папок нет, создаем их"""
        self.logger.info(os.getcwd())
        for d in [XML_TMP_FOLDER, ZIP_TMP_FOLDER]:
            if not os.path.isdir(d):
                try:
                    os.makedirs(d)
                    self.logger.info(f"Directory {os.getcwd()}//{d} created")
                except FileExistsError:
                    self.logger.warning(f"Directory {os.getcwd()}/{d} already exists")
                    return False
        return True

    def processing(self, ver: dict, prefix: str, name_file: str):
        """Качаем архив с данными ГАР и сохраняем архив в папку"""

        version = ver.get('VersionId', None)
        link_file = ver.get(prefix, None)
        name_file = get_name_file(version, name_file)
        model = self.get_model(version, link_file, name_file)
        self.logger.info(f"Prosessing <{name_file}>, version = <{version}>, link = <{link_file}>")

        if link_file == '':
            self.logger.info(f"Отсутствует ссылка на файл, продолжаем загрузку данных")
            model.delete()
            return 1
        if not model.download:
            model = self.services.download_file_zip(link_file, name_file, model)
            if model is None:
                self.logger.warning(f'Error downloads version={version}')
                return 0
        if not model.extract:
            model = self.unzip.unzip_address_file(name_file, model)
            if model is None:
                self.logger.warning(f'Error expract version={version}')
                return 0
        if not model.delete_zip_file:
            model = self.unzip.delete_zip(name_file, model)
            if model is None:
                self.logger.warning(f'Error delete ={version}')
                return 0
        return model

    def processing_loads(self, model: JournalLoadExtractFile, dir: str, is_full: int):
        """Загрузка данных из файла в монгу"""

        files = list()
        flag_error = True
        for f in model.files:
            name_f = f'{dir}//{f.name_file}'
            self.logger.info(f"Loads to MongoDB: Name file = {f.name_file}, version = <{model.version_id}>")
            if not os.path.isfile(name_f):
                if not f.processing:
                    self.logger.warning("Error: file not found")
                    f.error = f"Error: file not found",
                    f.end_at = datetime.datetime.utcnow() + datetime.timedelta(hours=5)
                    flag_error = False
                    continue
                continue

            prefix = prefix_file(f.name_file)
            tag = tag_name_file(f.name_file)
            if prefix is None or tag is None:
                self.logger.warning("Error: prefix or tag by file not found")
                f.error = f"Error: prefix or tag by file not found",
                f.end_at = datetime.datetime.utcnow() + datetime.timedelta(hours=5)
                flag_error = False
                continue

            if not self.load_data_to_mongo(name_f, tag, prefix, model.version_id, is_full):
                self.logger.warning("Error write file to mongo")
                f.error = f"Error write file to mongo",
                f.end_at = datetime.datetime.utcnow() + datetime.timedelta(hours=5)
                flag_error = False
                continue

            f.processing = True
            f.end_at = datetime.datetime.utcnow() + datetime.timedelta(hours=5)
            files.append(f)
            self.logger.info("Файл загружен")
            del_file(name_f)

        model.update(load_to_mongo=flag_error,
                     files=files,
                     end_at=datetime.datetime.utcnow() + datetime.timedelta(hours=5))
        self.logger.info(f"Результат загрузки версии <{model.version_id}> = {flag_error}")
        return model

    def get_model(self, version: int, link_file: str, name_file: str):
        model = self.mongo.load(version)
        if model is not None:
            return model
        model = self.mongo.new(version_id=version,
                               link_file=link_file,
                               name_zip_file=name_file)
        return model

    def load_data_to_mongo(self, file, tag_name, prefix, version_id: int, is_full: int):
        """Парсинг xml, деление на куски и загрузка файла"""

        data_list = []
        for _, element in ET.iterparse(file, tag=tag_name, encoding='UTF-8'):
            rec = convert_value(dict(element.attrib), tag_name)
            rec = join_corp_house_analitic(rec)
            rec = {**rec, **{'version_file': version_id}}
            rec = {k.lower(): v for k, v in rec.items()}
            data_list.append(rec)
            if len(data_list) == 10000:
                if not self.mongo.json_to_mongo(data_list, prefix, is_full):
                    return False
                data_list.clear()
            element.clear(keep_tail=True)
        if len(data_list) > 0:
            if not self.mongo.json_to_mongo(data_list, prefix, is_full):
                return False
        return True


class MongoControl(BaseControl):
    mongo_client = MongoDbClient
    model = JournalLoadExtractFile
    files = JournalProcessingFiles
    model_file = JournalFiles

    def __init__(self):
        self.db = self.mongo_client().db

    def get_current_version_files(self):
        model = self.model.objects(download=True, extract=True, delete_zip_file=True)
        self.logger.info(model)
        if len(model) == 0:
            if len([r.get("version_file") for r in self.db.version_file.find()]) == 0:
                return None
            return max([r.get("version_file") for r in self.db.version_file.find()])
        return max([r.version_id for r in model])

    def get_list_version_for_load(self):
        model = self.model.objects(download=True, extract=True, delete_zip_file=True, load_to_mongo=False)
        self.logger.info(model)
        if len(model) == 0:
            return None
        return sorted(model, key=lambda k: k.version_id)

    def new(self, **condition):
        return self.model(**condition).save()

    def new_file(self, **condition):
        return self.model_file(**condition).save()

    def load(self, version_id: int):
        return self.model.objects(version_id=version_id).first()

    def load_file(self, name_file: str):
        return self.model_file.objects(name_file=name_file).first()

    def new_files(self, **condition):
        return self.files(**condition)

    def json_to_mongo(self, data_list, prefix, is_full: int):
        if is_full == 1:
            self.db[f'{prefix}'].insert_many(data_list)
            return True

        if prefix not in FIELD_INSERT_DELTA:
            for d in data_list:
                self.db[f'{prefix}'].replace_one({"id": d['id']}, d, True)
        else:
            for d in data_list:
                self.db[f'{prefix}'].replace_one(
                    {f"{FIELD_INSERT_DELTA.get(f'{prefix}')}": d[FIELD_INSERT_DELTA.get(f'{prefix}')]}, d, True)
        return True


class GarServices(BaseControl):
    response_all = requests.get(url_all)

    def __init__(self):
        self.mongo = MongoControl()

    def versions_down(self, version: int):
        file = self.response_all.json()
        result = [f for f in file if f['VersionId'] > version]
        return sorted(result, key=lambda k: k['VersionId'])

    def versions_down_full(self):
        file = self.response_all.json()
        ver = max([f['VersionId'] for f in file if f['GarXMLFullURL'] != ""])
        result = [f for f in file if f['VersionId'] == ver]
        return result

    def download_file_zip(self, link: str, name_file: str, model: JournalLoadExtractFile) -> t.Optional[JournalLoadExtractFile]:
        urlretrieve(link, name_file)
        if not os.path.exists(name_file):
            self.logger.warning("Error download zip file")
            model.uppdate(error="Error download zip file")
            return None
        model.update(download=True)
        return model


class UnZIPFile(BaseControl):

    def __init__(self):
        self.mongo = MongoControl()

    def unzip_address_file(self, file: str, model: JournalLoadExtractFile) -> t.Optional[JournalLoadExtractFile]:
        files = list()
        try:
            with ZipFile(file) as zip:
                for zip_info in zip.infolist():
                    if zip_info.filename[-1] == '/':
                        continue
                    if zip_info.filename[0:3:1] not in ('72/', 'AS_'):
                        continue
                    zip_info.filename = os.path.basename(zip_info.filename)
                    zip.extract(zip_info, XML_TMP_FOLDER)

                    model_file = self.mongo.load_file(zip_info.filename)
                    if model_file is not None:
                        self.logger.info(f"Файл {zip_info.filename} обрабатывался {model_file.start_at}")
                        continue
                    self.mongo.new_file(name_file=zip_info.filename)
                    files.append(self.mongo.new_files(name_file=zip_info.filename))
        except BaseException:
            self.logger.warning("Error extract files")
            model.update(error="Error extract files")
            return None
        model.update(files=files, extract=True)
        return model

    def delete_zip(self, file: str, model: JournalLoadExtractFile) -> t.Optional[JournalLoadExtractFile]:
        if not del_file(file):
            self.logger.warning("Error delete zip file")
            model.update(error="Error delete zip file")
            return None
        model.update(delete_zip_file=True, end_at=datetime.datetime.utcnow() + datetime.timedelta(hours=5))
        return model

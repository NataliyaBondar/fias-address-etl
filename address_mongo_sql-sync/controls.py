from logging import getLogger
from .query_sql import QuerySql
from bson.json_util import dumps, RELAXED_JSON_OPTIONS

from .utils import convert_date_json, MongoDbClient
from .constants import limit
from .model import JournalLoadExtractFile, JournalProcessingFiles

logger = getLogger('controls')


class BaseControl(object):
    def __new__(cls, *args, **kwargs):
        cls.logger = logger.getChild(cls.__name__)
        return super().__new__(cls, *args, **kwargs)


class Control(BaseControl):
    provider_sql = QuerySql

    def __init__(self):
        self.mongo = MongoControl()
        self.db_sql = self.provider_sql()

    def control(self):
        version_sql = self.db_sql.get_version_file()
        list_versions_mongo = self.mongo.get_list_version_for_sql(version_sql)  # [20200609]
        list_collection_mongo = self.mongo.get_collections()

        self.logger.info(f"Версия в SQL (последняя) <{version_sql}>")
        self.logger.info(f"Версии для передачи данных <{list_versions_mongo}>")

        if list_versions_mongo is None:
            self.logger.info("Not found new data for address SQL")
            return

        for version in list_versions_mongo:    # ходим по версиям
            self.db_sql.change_version_file(version, 1)    # start_date
            self.db_sql.logs(f'Version = {version}, Result = "Начата обработка версии"')
            for col in list_collection_mongo:  # ходим по коллекциям
                if col in ['journal_load_extract_file', 'journal_files']:
                    continue
                result = self.processing_collection(col, version)
                if not result:
                    return self.logger.info("Error write data to SQL")
            # добавляем версию в sql
            self.db_sql.change_version_file(version, 2)    # end_date
        return True

    def processing_collection(self, col, version):
        count = int(self.mongo.count_data(col, version) / limit + 1)  # рассчитываем кол-во итераий для последовательного считывания
        self.db_sql.logs(f'Version = {version}, Collection = {col}, Limit = {limit}, Result = {count}')
        for skip in range(count):
            record_mongo = self.mongo.get_data(col, version, skip * limit, limit)
            record = [convert_date_json(rec) for rec in record_mongo]  # + преобразуем дату в нормальный формат для SQL
            js = dumps(record, ensure_ascii=False, json_options=RELAXED_JSON_OPTIONS)
         #  self.logger.info(js)
           # self.logger.info(f"{js}")
            result = self.db_sql.insert_data_gar(col, js)
            self.logger.info(f"{col} result to sql = <{result}>")
            if result != 'OK!':
                self.db_sql.logs(f"""Version = {version}, Collection = {col}, Iteration = {skip}, Skip = {skip * limit}, 
                                Limit = {limit}, Result = {result}""")
                return False
        return True


class MongoControl(BaseControl):
    mongo_client = MongoDbClient
    model = JournalLoadExtractFile
    files = JournalProcessingFiles

    def __init__(self):
        self.db = self.mongo_client().db

    def get_list_version_for_sql(self, version_id: int):
        model = self.model.objects(download=True, extract=True, delete_zip_file=True, load_to_mongo=True)
        result = [i.version_id for i in model if i.version_id > version_id]
        if len(result) == 0:
            return None
        return sorted(result)   # sorted(model, key=lambda k: k.version_id)

    def count_data(self, collection, version_id):
        return self.db[f'{collection}'].count_documents({"version_file": version_id})

    def get_data(self, collection, version_id, skip, limit):
        return [r for r in self.db[f'{collection}'].find({"version_file": version_id}).skip(skip).limit(limit)]

    def get_collections(self):
        return self.db.list_collection_names()

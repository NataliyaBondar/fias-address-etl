from datetime import datetime
from logging import getLogger
from pymongo import MongoClient
from config.json import Config
import shutil
import os.path
import re
from .constants import FILE_DELTA_SAVE_EXTENSION, ZIP_TMP_FOLDER, \
    FILES, ATTR_STR

logger = getLogger('utils')


class BaseControl(object):
    def __new__(cls, *args, **kwargs):
        cls.logger = logger.getChild(cls.__name__)
        return super().__new__(cls, *args, **kwargs)


class MongoDbClient(BaseControl):

    def __init__(self):
        config = Config(section="app.mongodb_settings")
        self.client = MongoClient(
            config.host,
            config.port,
            username=config.username,
            password=config.password
        )

        self.db = self.client.get_database(config.db)


def get_name_file(version, file: str):     # получить имя файла
    return f'{ZIP_TMP_FOLDER}//{file}_{version}{FILE_DELTA_SAVE_EXTENSION}'


def del_file(file: str):
    try:
        shutil.rmtree(file)
    except OSError:
        os.remove(file)
    return not os.path.isfile(rf'{file}')


def prefix_file(filename):    # получение префикса (тип файла)
    file_str = re.search(r'[AS_]\D+_', filename)

    if file_str[0] not in FILES.keys():
        return None
    return FILES[file_str[0]]['prefix']


def tag_name_file(filename):  # получения Тэга файла (для парсинга xml)
    file_str = re.search(r'[AS_]\D+_', filename)

    if file_str[0] not in FILES.keys():
        return None
    return FILES[file_str[0]]['tag']


def isdate(str):  # преобразование строки в дату
    try:
        datetime.strptime(str, "%Y-%m-%d")
        return True
    except ValueError:
        return False


def convert_value(data, tag_name):  # преобразовать строку в число
    for k, v in data.items():
        if v.isdigit() and k not in ATTR_STR.get(tag_name):
            data[k] = int(v)
        elif isdate(v):
            data[k] = datetime.strptime(v, "%Y-%m-%d")
    return data


def join_corp_house(type, num, data):   # разбивка дома на корпус, строение, сооружение - child
    data_new = dict()
    if data[type] == 1:
        data_new['corp'] = data[num]
    elif data[type] == 2:
        data_new['build'] = data[num]
    elif data[type] == 3:
        data_new['struct'] = data[num]
    elif data[type] == 4:
        data_new['liter'] = data[num]
    return data_new


def join_corp_house_analitic(data):     # разбивка дома на корпус, строение, сооружение - main
    if 'ADDNUM1' in data:
        data_new = join_corp_house('ADDTYPE1', 'ADDNUM1', data)
        data.pop('ADDTYPE1')
        data.pop('ADDNUM1')
        data = {**data, **data_new}
    if 'ADDNUM2' in data:
        data_new = join_corp_house('ADDTYPE2', 'ADDNUM2', data)
        data.pop('ADDTYPE2')
        data.pop('ADDNUM2')
        data = {**data, **data_new}
    return data

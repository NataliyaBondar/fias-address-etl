from datetime import datetime
from logging import getLogger
from pymongo import MongoClient
from config.json import Config

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


def convert_date_json(obj):
    for k, v in obj.items():
        if isinstance(v, datetime):
            obj[k] = v.isoformat()
    return obj

from logging.config import dictConfig
import mongoengine
from config.json import Config
from .controls import Control
import mssql

__all__ = ['create_app', 'register']


def create_app(config=None):
    config = config if isinstance(config, Config) else Config()
    setup(config)
    mongoengine.connect(**config.extract('app.mongodb_settings').all())
    mssql.connect(**config.database)
    return Control().control()


def setup(config: Config) -> None:
    if config.get('logging') is not None:
        dictConfig(config.get('logging'))

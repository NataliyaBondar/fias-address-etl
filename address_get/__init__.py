from logging.config import dictConfig
import mongoengine
from config.json import Config
from .controls import Control

__all__ = ['create_app']


def create_app(config=None):
    config = config if isinstance(config, Config) else Config()
    setup(config)
    mongoengine.connect(**config.extract('app.mongodb_settings').all())
    return Control().control()


def setup(config: Config) -> None:
    if config.get('logging') is not None:
        dictConfig(config.get('logging'))

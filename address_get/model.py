from __future__ import annotations
from mongoengine import fields as f, Document, EmbeddedDocument
import datetime


class JournalProcessingFiles(EmbeddedDocument):
    name_file = f.StringField(required=True)
    processing = f.BooleanField(default=False)
    start_at = f.DateTimeField(default=datetime.datetime.utcnow() + datetime.timedelta(hours=5))
    end_at = f.DateTimeField(default=None)
    error = f.StringField(default=None)


class JournalLoadExtractFile(Document):
    version_id = f.IntField(required=True)
    link_file = f.StringField(required=True)
    name_zip_file = f.StringField(required=True)

    download = f.BooleanField(default=False)
    extract = f.BooleanField(default=False)
    delete_zip_file = f.BooleanField(default=False)
    load_to_mongo = f.BooleanField(default=False)

    start_at = f.DateTimeField(default=datetime.datetime.utcnow() + datetime.timedelta(hours=5))
    end_at = f.DateTimeField(default=None)
    error = f.StringField(default=None)
    files = f.EmbeddedDocumentListField(JournalProcessingFiles)


class JournalFiles(Document):
    name_file = f.StringField(required=True)
    start_at = f.DateTimeField(default=datetime.datetime.utcnow() + datetime.timedelta(hours=5))

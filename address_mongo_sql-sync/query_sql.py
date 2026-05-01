from logging import getLogger
import mssql

logger = getLogger('mssql')


class BaseDBQuery(mssql.BaseDBQuery):
    def __new__(cls, **kwargs):
        obj = super().__new__(cls)
        obj.logger = logger.getChild(cls.__name__)
        return obj


class QuerySql(BaseDBQuery):
    def insert_data_gar(self, prefix, json_data):
        query = f"""exec LoadDataGAR_delta '{prefix}', '{json_data}' """
        curr = self.call(query)
        if curr.rowcount == 0:
            curr.close()
            return False
        return curr.fetchval()

    def get_version_file(self):
        query = f"""select get_version_file()"""
        curr = self.call(query)
        if curr.rowcount == 0:
            curr.close()
            return False
        result = curr.fetchval()
        return result if result else None

    def change_version_file(self, version, pr):
        query = f"""exec ChangeVersionFile {version}, {pr} """
        curr = self.call(query)
        if curr.rowcount == 0:
            curr.close()
            return False
        result = curr.fetchval()
        return len(result) > 0 and result == 'OK!'

    def logs(self, log):
        query = f"""exec logs '{log}'"""
        curr = self.call(query)
        if curr.rowcount == 0:
            curr.close()
            return False
        result = curr.fetchval()
        return len(result) > 0 and result == 'OK!'

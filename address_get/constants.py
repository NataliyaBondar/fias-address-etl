ZIP_TMP_FOLDER = '.fias//.zip_tmp'   # сохранение файла zip
XML_TMP_FOLDER = '.fias//.xml_tmp'   # распаковка файла zip

FILE_DELTA_SAVE_EXTENSION = r'.zip'

LINK_FILE = {
    "full": "GarXMLFullURL",
    "delta": "GarXMLDeltaURL"
}

FILE_SAVE_NAME = {  # Имя сохраняемого файла
    "full": "fias_full_xml",
    "delta": "fias_delta_xml"
}

url_all = 'http://fias.nalog.ru/WebServices/Public/GetAllDownloadFileInfo'

DEFAULT_RESTCLIENT_HEADERS = {'Content-Type': 'application/json;charset=utf-8'}


# типы файлов, которые подлежат обработке
FIELD_INSERT_DELTA = {
    'change_history': 'changeid',
    'object_levels': 'level',
    'reestr_objects': 'objectid'
}

FILES = {
        'AS_ADDHOUSE_TYPES_': {
            'prefix': 'addhouse_types',
            'tag': 'HOUSETYPE'
        },
        'AS_ADDRESS_OBJECT_DIVISION_': {
            'prefix': 'addr_obj_division',
            'tag': 'ITEM'
        },
        'AS_ADDRESS_OBJECTS_': {
            'prefix': 'addr_obj',
            'tag': 'OBJECT'
        },
        'AS_ADDRESS_OBJECTS_PARAMS_': {
            'prefix': 'addr_obj_param',
            'tag': 'PARAM'
        },
        'AS_ADDR_OBJ_DIVISION_': {
            'prefix': 'addr_obj_division',
            'tag': 'ITEM'
        },
        'AS_ADDR_OBJ_': {
            'prefix': 'addr_obj',
            'tag': 'OBJECT'
        },
        'AS_ADDR_OBJ_PARAMS_': {
            'prefix': 'addr_obj_param',
            'tag': 'PARAM'
        },
        'AS_ADM_HIERARCHY_': {
            'prefix': 'adm_hierarchy',
            'tag': 'ITEM'
        },
        'AS_APARTMENT_TYPES_': {
            'prefix': 'apartment_types',
            'tag': 'APARTMENTTYPE'
        },
        'AS_APARTMENTS_': {
            'prefix': 'apartments',
            'tag': 'APARTMENT'
        },
        'AS_APARTMENTS_PARAMS_': {
            'prefix': 'apartments_params',
            'tag': 'PARAM'
        },
        'AS_CAR.PLACES_': {
            'prefix': 'carplaces',
            'tag': 'CARPLACE'
        },
        'AS_CARPLACES_': {
            'prefix': 'carplaces',
            'tag': 'CARPLACE'
        },
        'AS_CARPLACES_PARAMS_': {
            'prefix': 'carplaces_params',
            'tag': 'PARAM'
        },
        'AS_CHANGE_HISTORY_': {
            'prefix': 'change_history',
            'tag': 'ITEM'
        },
        'AS_HOUSE_TYPES_': {
            'prefix': 'house_types',
            'tag': 'HOUSETYPE'
        },
        'AS_HOUSES_': {
            'prefix': 'houses',
            'tag': 'HOUSE'
        },
        'AS_HOUSES_PARAMS_': {
            'prefix': 'houses_params',
            'tag': 'PARAM'
        },
        'AS_MUN_HIERARCHY_': {
            'prefix': 'mun_hierarchy',
            'tag': 'ITEM'
        },
        'AS_NORMDOCS_': {
            'prefix': 'normative_docs',
            'tag': 'NORMDOC'
        },
        'AS_NORMDOCS_KINDS_': {
            'prefix': 'normative_docs_kinds',
            'tag': 'NDOCKIND'
        },
        'AS_NORMDOCS_TYPES_': {
            'prefix': 'normative_docs_types',
            'tag': 'NDOCTYPE'
        },
        'AS_NORMATIVE_DOCS_': {
            'prefix': 'normative_docs',
            'tag': 'NORMDOC'
        },
        'AS_NORMATIVE_DOCS_KINDS_': {
            'prefix': 'normative_docs_kinds',
            'tag': 'NDOCKIND'
        },
        'AS_NORMATIVE_DOCS_TYPES_': {
            'prefix': 'normative_docs_types',
            'tag': 'NDOCTYPE'
        },
        'AS_OBJECT_LEVELS_': {
            'prefix': 'object_levels',
            'tag': 'OBJECTLEVEL'
        },
        'AS_OBJECT_TYPES_': {
            'prefix': 'addr_obj_types',
            'tag': 'ADDRESSOBJECTTYPE'
        },
        'AS_ADDR_OBJ_TYPES_': {
            'prefix': 'addr_obj_types',
            'tag': 'ADDRESSOBJECTTYPE'
        },
        'AS_OPERATION_TYPES_': {
            'prefix': 'operation_types',
            'tag': 'OPERATIONTYPE'
        },
        'AS_PARAM_TYPES_': {
            'prefix': 'param_types',
            'tag': 'PARAMTYPE'
        },
        'AS_ROOM_TYPES_': {
            'prefix': 'room_types',
            'tag': 'ROOMTYPE'
        },
        'AS_ROOMS_': {
            'prefix': 'rooms',
            'tag': 'ROOM'
        },
        'AS_ROOMS_PARAMS_': {
            'prefix': 'rooms_params',
            'tag': 'PARAM'
        },
        'AS_STEADS_': {
            'prefix': 'steads',
            'tag': 'STEAD'
        },
        'AS_STEADS_PARAMS_': {
            'prefix': 'steads_params',
            'tag': 'PARAM'
        },
        'AS_REESTR_OBJECTS_': {
                    'prefix': 'reestr_objects',
                    'tag': 'OBJECT'
                }
    }

ATTR_STR = {
    'STEAD': ['NUMBER', 'OPERTYPEID'],
    'ROOM': ['ROOMNUMBER', 'OPERTYPEID'],
    'PARAM': ['VALUE'],
    'OPERATIONTYPE': ['ID'],
    'NORMDOC': ['NUMBER'],
    'HOUSE': ['HOUSENUM', 'ADDNUM1', 'ADDNUM2', 'OPERTYPEID'],
    'CARPLACE': ['NUMBER', 'OPERTYPEID'],
    'APARTMENT': ['NUMBER', 'APARTTYPE', 'OPERTYPEID'],
    'ITEM': ['REGIONCODE', 'AREACODE', 'CITYCODE', 'PLACECODE', 'PLANCODE', 'STREETCODE', 'OPERTYPEID'],
    'OBJECT': ['NAME', 'OPERTYPEID'],
    'ROOMTYPE': [],
    'PARAMTYPE': [],
    'ADDRESSOBJECTTYPE': [],
    'OBJECTLEVEL': [],
    'NDOCTYPE': [],
    'NDOCKIND': [],
    'HOUSETYPE': [],
    'APARTMENTTYPE': []
}

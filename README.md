![Python](https://img.shields.io/badge/Python-ETL-blue)
![MongoDB](https://img.shields.io/badge/MongoDB-Raw-green)
![MS SQL](https://img.shields.io/badge/MS_SQL-DWH-red)
![Status](https://img.shields.io/badge/status-active-success)

## PROJECT: Address Integration and Normalization System
## ПРОЕКТ: Система интеграции и нормализации адресов

### 📌 Project Description

An address data synchronization and normalization system was developed.  
The solution includes an ETL pipeline for regular updates of the address database and a user interface for address matching.

### 📌 Описание проекта

Разработана система синхронизации и нормализации адресных данных.  
Решение включает ETL-пайплайн для регулярного обновления адресной базы и пользовательский интерфейс для сопоставления адресов.

### 🎯 1. Business Problem

Inconsistent address data was used in the system, which led to:
- data duplication  
- reporting errors  
- inability to perform accurate analytics

### 🎯 1.	Бизнес-задача
В системе использовались несогласованные адреса, что приводило к:
-	дублированию данных 
-	ошибкам в отчётности 
-	невозможности точной аналитики 

---

**Goal:** 
- standardize addresses to a unified format
- ensure regular data updates

**Цель:**
-	привести адреса к единому стандарту
-	обеспечить регулярное обновление данных

---

### 🏗 2.	Solution Architecture | Архитектура решения
<img width="1440" height="694" alt="ФИАС (1)" src="https://github.com/user-attachments/assets/be4f5005-f3a8-436d-bf1f-9d93670b22a8" />

---

### ⚙️ 3.	Technical Implementation | Техническая реализация

**1. Data Ingestion and Processing** [python: **address_get**](https://github.com/NataliyaBondar/fias-address-etl/tree/main/address_get)

- working with the service / ZIP / XML files  
- delta data loading  
- XML parsing  
- structure normalization  

**1. Загрузка и обработка данных** [python: **address_get**](https://github.com/NataliyaBondar/fias-address-etl/tree/main/address_get)

- работа с Сервисом / файлами ZIP / XML
- загрузка дельты
- парсинг XML
- нормализация структуры

---

**2. Data Storage in MongoDB** [schema mongodb-json](https://github.com/NataliyaBondar/fias-address-etl/blob/main/schema_mongodb_json/schema.json)

**The database is designed based on the following principles:**

1. Normalized data model
2. Separation into:
- reference data (types)
- entities (addresses, houses, apartments)
- parameters (params)
- hierarchies (hierarchy)

**Main Collections:**
1. Address objects (addr_obj, addr_obj_division, addr_obj_param)
2. Houses and real estate objects (houses, apartments, rooms, carplaces, steads)
3. Object parameters (houses_params, apartments_params, rooms_params, carplaces_params, steads_params)
4. Reference data (addr_obj_types, house_types, apartment_types, room_types, param_types)
5. Hierarchies (adm_hierarchy, mun_hierarchy)
6. Change history (change_history)
7. ETL / data loading (journal_load_extract_file, journal_files)

**2. Хранилище данных в MongoDB** [schema mongodb-json](https://github.com/NataliyaBondar/fias-address-etl/blob/main/schema_mongodb_json/schema.json)

**База данных построена по принципу:**

1. Нормализованная модель
2. Разделение на:
- справочники (types)
- сущности (addresses, houses, apartments)
- параметры (params)
- иерархии (hierarchy)

**Основные коллекции:**
1. Адресные объекты (addr_obj, addr_obj_division, addr_obj_param)
2. Дома и объекты недвижимости (houses, apartments, rooms, carplaces, steads)
3. Параметры объектов (houses_params, apartments_params, rooms_params, carplaces_params, steads_params)
4. Справочники (addr_obj_types, house_types, apartment_types, room_types, param_types)
5. Иерархии (adm_hierarchy, mun_hierarchy)
6. История изменений (change_history)
7. ETL / загрузка данных (journal_load_extract_file, journal_files)

---

**3. ELT between MongoDB and MS SQL** [python **address_mongo_sql_sync**](https://github.com/NataliyaBondar/fias-address-etl/tree/main/address_mongo_sql-sync)  
- change data extraction  
- delta-only loading

**3. ELT между MongoDB и MS SQL** [python **address_mongo_sql_sync**](https://github.com/NataliyaBondar/fias-address-etl/tree/main/address_mongo_sql-sync)
- выборка изменений
- загрузка только дельты

---

**4. Address Synchronization in MS SQL**

- [synchronization of streets, localities, and planning structure](https://github.com/NataliyaBondar/fias-address-etl/blob/main/mssql_sync/update_street_child.sql)  
- [house synchronization](https://github.com/NataliyaBondar/fias-address-etl/blob/main/mssql_sync/update_house.sql)  

**4. Синхронизация адресов в MS SQL**

- [синхронизация улиц, населенных пунктов, планировочной структуры](https://github.com/NataliyaBondar/fias-address-etl/blob/main/mssql_sync/update_street_child.sql)
- [синхронизация домов](https://github.com/NataliyaBondar/fias-address-etl/blob/main/mssql_sync/update_house.sql)

---

**5. User Module**

- [Delphi application](https://github.com/NataliyaBondar/fias-address-etl/tree/main/user_address_module/delphi)  
- [stored procedures in MS SQL](https://github.com/NataliyaBondar/fias-address-etl/blob/main/user_address_module/mssql/XMLProcessing400.sql)
  
**5. Пользовательский модуль**

- [приложение на Delphi](https://github.com/NataliyaBondar/fias-address-etl/tree/main/user_address_module/delphi)
- [хранимые процедуры в MS SQL](https://github.com/NataliyaBondar/fias-address-etl/blob/main/user_address_module/mssql/XMLProcessing400.sql)

<img width="727" height="502" alt="image" src="https://github.com/user-attachments/assets/ab573d7f-cea8-4b46-874a-8f905cb0583c" />

<img width="523" height="255" alt="image" src="https://github.com/user-attachments/assets/d1bfbc86-99ed-4937-b7f2-d08675b399e0" />

---

### 🧠 SKILLS | НАВЫКИ

✔ ETL
✔ MS SQL | MongoDB
✔ Python | Delphi


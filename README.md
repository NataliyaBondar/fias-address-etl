## PROJECT: Address Integration and Normalization System
## ПРОЕКТ: Система интеграции и нормализации адресов

### Project Description

An address data synchronization and normalization system was developed.  
The solution includes an ETL pipeline for regular updates of the address database and a user interface for address matching.

### Описание проекта

Разработана система синхронизации и нормализации адресных данных.  
Решение включает ETL-пайплайн для регулярного обновления адресной базы и пользовательский интерфейс для сопоставления адресов.

### 1. Business Problem

Inconsistent address data was used in the system, which led to:
- data duplication  
- reporting errors  
- inability to perform accurate analytics

### 1.	Бизнес-задача
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

### 2.	Solution Architecture | Архитектура решения
<img width="1270" height="787" alt="ФИАС" src="https://github.com/user-attachments/assets/8a64da32-a412-4d91-8bf6-94bf7b0b12ee" />

---

### 3.	Technical Implementation | Техническая реализация

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

**2. Хранилище данных в MongoDB**
- схема

**3. ELT между MongoDB и MS SQL**
- выборка изменений
- загрузка только дельты

код на Python

**4. Синхронизация адресов в MS SQL**

код на TSQL

**5. Пользовательский модуль**

- приложение на Delphi
- хранимые процедуры в MS SQL

### НАВЫКИ

✔ ETL
✔ работа с API
✔ MS SQL | MongoDB
✔ Python | Delphi


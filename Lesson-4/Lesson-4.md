# Логический уровень PostgreSQL. 
## Домашнее задание.
1. создайте новый кластер PostgresSQL 14

    - С помощью docker запустил образ ubuntu:22.04. 
    - Установка PostgresSQL 14.
      ```
       apt update \
        &&  apt install -y curl ca-certificates lsb-release \
        &&  curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        &&  install -d /usr/share/postgresql-common/pgdg \
        &&  sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
        && apt update \
        && apt -y install postgresql-14 \
        && su postgres \
        && export PGDATA=/var/lib/postgresql/14/main/
        && pg_ctlcluster 14 main start
      ```
      ```
      postgres@a20042f3d60a:/$ pg_ctlcluster 14 main status
      pg_ctl: server is running (PID: 6449)
      /usr/lib/postgresql/14/bin/postgres "-D" "/var/lib/postgresql/14/main" "-c" "config_file=/etc/postgresql/14/main/postgresql.conf"

2. зайдите в созданный кластер под пользователем postgres
   ```
   postgres@a20042f3d60a:/$ psql
   psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
   Type "help" for help.

   postgres=# 

3. создайте новую базу данных testdb
   ```
   postgres=# CREATE DATABASE testdb;
   CREATE DATABASE
   postgres=# \l
                                 List of databases
      Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
   -----------+----------+----------+---------+---------+-----------------------
    postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
    template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
              |          |          |         |         | postgres=CTc/postgres
    template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
              |          |          |         |         | postgres=CTc/postgres
    testdb    | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
   (4 rows)

4. зайдите в созданную базу данных под пользователем postgres
   ```
   postgres=# \c testdb 
   You are now connected to database "testdb" as user "postgres".
5. создайте новую схему testnm
   ```
   testdb=# CREATE SCHEMA testnm;
   CREATE SCHEMA
   
   testdb=# \dn+
                             List of schemas
     Name  |  Owner   |  Access privileges   |      Description       
   --------+----------+----------------------+------------------------
    public | postgres | postgres=UC/postgres+| standard public schema
           |          | =UC/postgres         | 
    testnm | postgres |                      | 
   (2 rows)
   
6. создайте новую таблицу t1 с одной колонкой c1 типа integer
   ```
   testdb=# CREATE TABLE t1(c1 integer);
   CREATE TABLE
   testdb=# \dt
           List of relations
    Schema | Name | Type  |  Owner   
   --------+------+-------+----------
    public | t1   | table | postgres
   (1 row)

7. вставьте строку со значением c1=1
   ```
   testdb=# INSERT INTO t1 values(1);
   INSERT 0 1

8. создайте новую роль readonly
   ```
   testdb=# CREATE role readonly;
   CREATE ROLE

9. дайте новой роли право на подключение к базе данных testdb
   ```
   testdb=# grant connect on DATABASE testdb TO readonly;
   GRANT

10. дайте новой роли право на использование схемы testnm
    ```
    grant usage on SCHEMA testnm to readonly;

11. дайте новой роли право на select для всех таблиц схемы testnm
    ```
    testdb=# grant SELECT on all TABLEs in SCHEMA testnm TO readonly;
    GRANT
12. создайте пользователя testread с паролем test123
    ```
    testdb=# CREATE USER testread with password 'test123';
    CREATE ROLE
13. дайте роль readonly пользователю testread
    ```
    testdb=# grant readonly TO testread;
    GRANT ROLE
14. зайдите под пользователем testread в базу данных testdb
    ```
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=>
15. сделайте select * from t1;
    ```
    testdb=> SELECT * FROM t1;
    ERROR:  permission denied for table t1
    testdb=>
16. получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)
    - нет
17. напишите что именно произошло в тексте домашнего задания
    - Пользователь testread не может получить доступ к таблице t1. 
18. у вас есть идеи почему? ведь права то дали?
    - Права чтения на саму таблицу t1 не давали. Дали права на использование схемы testnm. Таблицы t1 в этой схеме нет.
19. посмотрите на список таблиц
    ```
    testdb=> \dt+
                                         List of relations
     Schema | Name | Type  |  Owner   | Persistence | Access method |    Size    | Description 
    --------+------+-------+----------+-------------+---------------+------------+-------------
     public | t1   | table | postgres | permanent   | heap          | 8192 bytes | 
    (1 row)
    
20. подсказка в шпаргалке под пунктом 20
21. а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)
    - При создании таблицы без явного указания схемы, используется схема public.
22. вернитесь в базу данных testdb под пользователем postgres
    ```
    testdb=> \q
    postgres@a20042f3d60a:/$ psql
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    Type "help" for help.
    
    postgres=#
23. удалите таблицу t1
    ```
     postgres=# \c testdb
     You are now connected to database "testdb" as user "postgres".
     testdb=# DROP TABLE t1;
     DROP TABLE
24. создайте ее заново но уже с явным указанием имени схемы testnm
    ```
    testdb=# CREATE TABLE testnm.t1(c1 integer);
    CREATE TABLE
25. вставьте строку со значением c1=1
    ```
    testdb=# INSERT INTO testnm.t1 values(1);
    INSERT 0 1
26. зайдите под пользователем testread в базу данных testdb
    ```
    testdb=# \q
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=>    
27. сделайте select * from testnm.t1;
    ```
    testdb=> select * from testnm.t1;
    ERROR:  permission denied for schema testnm
    LINE 1: select * from testnm.t1;
                          ^
    testdb=>
28. получилось?
    - Нет
29. есть идеи почему? если нет - смотрите шпаргалку
    - Пересоздали таблицу t1. Доступ пропал.
    ```
    testdb=> \dt+
    Did not find any relations.
30. как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку
    - изменить доступ по умолчанию в схеме testnm.
    ```
    testdb=> \q
    postgres@a20042f3d60a:/$ psql
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    Type "help" for help.
    postgres=# \c testdb               
    You are now connected to database "testdb" as user "postgres".
    testdb=# ALTER default privileges in SCHEMA testnm grant SELECT on TABLES to readonly; 
    ALTER DEFAULT PRIVILEGES
31. сделайте select * from testnm.t1;
    ```
    testdb=# \q
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=> select * from testnm.t1;
    ERROR:  permission denied for table t1
32. получилось?
    - Нет
33. есть идеи почему? если нет - смотрите шпаргалку
    - ALTER DEFAULT PRIVILEGES прменяется только к новым таблицам. Повторяем grant SELECT.
    ```
    testdb=> \q
    postgres@a20042f3d60a:/$ psql
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    Type "help" for help.
    
    postgres=# \c testdb
    You are now connected to database "testdb" as user "postgres".
    testdb=# grant SELECT on all TABLEs in SCHEMA testnm TO readonly;
    GRANT
    testdb=# \q
34. сделайте select * from testnm.t1;
    ```
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=> select * from testnm.t1;
     c1 
    ----
      1
    (1 row)
    
    testdb=> 
35. получилось?
    - Да
36. ура!
37. теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
    ```
    testdb=> create table t2(c1 integer); insert into t2 values (2);
    CREATE TABLE
    INSERT 0 1
    testdb=> select * from t2;
     c1 
    ----
      2
    (1 row)
    
38. а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
    - схема по умочанию public. Роль public дается все пользователям.
    ```
    testdb=> select * from public.t2;
     c1 
    ----
      2
    (1 row) 
39. есть идеи как убрать эти права? если нет - смотрите шпаргалку
40. если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды
    ```
    testdb=> \q
    postgres@a20042f3d60a:/$ psql
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    Type "help" for help.
    
    postgres=# \c testdb
    You are now connected to database "testdb" as user "postgres".
    testdb=# REVOKE CREATE on SCHEMA public FROM public;
    REVOKE
    ```
    - убрали привилегию на создание в схеме public для всех пользователей, кроме владельца и суперпользователя.
    ```
    testdb=# REVOKE ALL on DATABASE testdb FROM public;
    REVOKE
    ```
    - убрали все привелегии public. Подключится к базе может только собственник. 

41. теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
расскажите что получилось и почему
    ```
    testdb=> create table t3(c1 integer);
    ERROR:  permission denied for schema public
    LINE 1: create table t3(c1 integer);
                         ^
    testdb=>
    ```
    - Мы отозвали права для создания в схеме public.

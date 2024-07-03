# MVCC, vacuum и autovacuum. 
## Домашнее задание.
1. Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB

    - VM Ubuntu 22.04. 2 CPU, 4gb, SSD 10GB. 
    - Установить на него PostgreSQL 15 с дефолтными настройками.
      ```
       sudo apt update \
        && sudo apt install -y curl ca-certificates lsb-release \
        && sudo mkdir -p /usr/share/postgresql-common/pgdg/ \
        && sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        && sudo install -d /usr/share/postgresql-common/pgdg \
        && sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
        && sudo apt update \
        && sudo apt -y install postgresql-15 \
        && sudo systemctl start postgresql@15-main
      ```
      ```
      user7@test7:~$ sudo systemctl status postgresql@15-main
      ● postgresql@15-main.service - PostgreSQL Cluster 15-main
           Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
           Active: active (running) since Tue 2024-07-02 19:32:26 UTC; 1min 16s ago
          Process: 5451 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=0/SUCCESS)
         Main PID: 5456 (postgres)
            Tasks: 6 (limit: 4557)
           Memory: 19.6M
              CPU: 606ms
           CGroup: /system.slice/system-postgresql.slice/postgresql@15-main.service
                   ├─5456 /usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/15/main -c config_file=/etc/postgresql/15/main/postgresql.conf
                   ├─5457 "postgres: 15/main: checkpointer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
                   ├─5458 "postgres: 15/main: background writer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "">
                   ├─5460 "postgres: 15/main: walwriter " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
                   ├─5461 "postgres: 15/main: autovacuum launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
                   └─5462 "postgres: 15/main: logical replication launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >

      Jul 02 19:32:23 test7 systemd[1]: Starting PostgreSQL Cluster 15-main...
      Jul 02 19:32:26 test7 systemd[1]: Started PostgreSQL Cluster 15-main.
        

2. Создать БД для тестов: выполнить pgbench -i postgres
   ```
   sudo su postgres
   ```
   ```
   postgres@test7:/home/user7$ pgbench -i postgres
   dropping old tables...
   NOTICE:  table "pgbench_accounts" does not exist, skipping
   NOTICE:  table "pgbench_branches" does not exist, skipping
   NOTICE:  table "pgbench_history" does not exist, skipping
   NOTICE:  table "pgbench_tellers" does not exist, skipping
   creating tables...
   generating data (client-side)...
   100000 of 100000 tuples (100%) done (elapsed 0.44 s, remaining 0.00 s)
   vacuuming...
   creating primary keys...
   done in 2.37 s (drop tables 0.00 s, create tables 0.05 s, client-side generate 1.37 s, vacuum 0.15 s, primary keys 0.80 s).
   postgres@test7:/home/user7

3. Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
   ```
   postgres@test7:/home/user7$ pgbench -c8 -P 6 -T 60 -U postgres postgres
   pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
   starting vacuum...end.
   progress: 6.0 s, 189.0 tps, lat 41.385 ms stddev 23.112, 0 failed
   progress: 12.0 s, 196.7 tps, lat 40.864 ms stddev 22.781, 0 failed
   progress: 18.0 s, 194.3 tps, lat 41.161 ms stddev 22.421, 0 failed
   progress: 24.0 s, 204.2 tps, lat 39.170 ms stddev 20.769, 0 failed
   progress: 30.0 s, 186.5 tps, lat 42.887 ms stddev 22.320, 0 failed
   progress: 36.0 s, 203.8 tps, lat 39.247 ms stddev 21.860, 0 failed
   progress: 42.0 s, 201.2 tps, lat 39.771 ms stddev 21.434, 0 failed
   progress: 48.0 s, 208.3 tps, lat 38.373 ms stddev 19.237, 0 failed
   progress: 54.0 s, 187.3 tps, lat 42.744 ms stddev 24.279, 0 failed
   progress: 60.0 s, 147.0 tps, lat 54.235 ms stddev 35.776, 0 failed
   transaction type: <builtin: TPC-B (sort of)>
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 60 s
   number of transactions actually processed: 11518
   number of failed transactions: 0 (0.000%)
   latency average = 41.642 ms
   latency stddev = 23.712 ms
   initial connection time = 83.555 ms
   tps = 192.027030 (without initial connection time)
   postgres@test7:/home/user7$

Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
Протестировать заново
Что изменилось и почему?
Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
Посмотреть размер файла с таблицей
5 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
Подождать некоторое время, проверяя, пришел ли автовакуум
5 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть размер файла с таблицей
Отключить Автовакуум на конкретной таблице
10 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть размер файла с таблицей
Объясните полученный результат
Не забудьте включить автовакуум)
Задание со *:
Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице.
Не забыть вывести номер шага цикла.
1. зайдите в созданный кластер под пользователем postgres
   ```
   postgres@a20042f3d60a:/$ psql
   psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
   Type "help" for help.

   postgres=# 

2. создайте новую базу данных testdb
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

3. зайдите в созданную базу данных под пользователем postgres
   ```
   postgres=# \c testdb 
   You are now connected to database "testdb" as user "postgres".
4. создайте новую схему testnm
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
   
5. создайте новую таблицу t1 с одной колонкой c1 типа integer
   ```
   testdb=# CREATE TABLE t1(c1 integer);
   CREATE TABLE
   testdb=# \dt
           List of relations
    Schema | Name | Type  |  Owner   
   --------+------+-------+----------
    public | t1   | table | postgres
   (1 row)

6. вставьте строку со значением c1=1
   ```
   testdb=# INSERT INTO t1 values(1);
   INSERT 0 1

7. создайте новую роль readonly
   ```
   testdb=# CREATE role readonly;
   CREATE ROLE

8. дайте новой роли право на подключение к базе данных testdb
   ```
   testdb=# grant connect on DATABASE testdb TO readonly;
   GRANT

9.  дайте новой роли право на использование схемы testnm
    ```
    grant usage on SCHEMA testnm to readonly;

10. дайте новой роли право на select для всех таблиц схемы testnm
    ```
    testdb=# grant SELECT on all TABLEs in SCHEMA testnm TO readonly;
    GRANT
11. создайте пользователя testread с паролем test123
    ```
    testdb=# CREATE USER testread with password 'test123';
    CREATE ROLE
12. дайте роль readonly пользователю testread
    ```
    testdb=# grant readonly TO testread;
    GRANT ROLE
13. зайдите под пользователем testread в базу данных testdb
    ```
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=>
14. сделайте select * from t1;
    ```
    testdb=> SELECT * FROM t1;
    ERROR:  permission denied for table t1
    testdb=>
15. получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)
    - нет
16. напишите что именно произошло в тексте домашнего задания
    - Пользователь testread не может получить доступ к таблице t1. 
17. у вас есть идеи почему? ведь права то дали?
    - Права чтения на саму таблицу t1 не давали. Дали права на использование схемы testnm. Таблицы t1 в этой схеме нет.
18. посмотрите на список таблиц
    ```
    testdb=> \dt+
                                         List of relations
     Schema | Name | Type  |  Owner   | Persistence | Access method |    Size    | Description 
    --------+------+-------+----------+-------------+---------------+------------+-------------
     public | t1   | table | postgres | permanent   | heap          | 8192 bytes | 
    (1 row)
    
19. подсказка в шпаргалке под пунктом 20
20. а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)
    - При создании таблицы без явного указания схемы, используется схема public.
21. вернитесь в базу данных testdb под пользователем postgres
    ```
    testdb=> \q
    postgres@a20042f3d60a:/$ psql
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    Type "help" for help.
    
    postgres=#
22. удалите таблицу t1
    ```
     postgres=# \c testdb
     You are now connected to database "testdb" as user "postgres".
     testdb=# DROP TABLE t1;
     DROP TABLE
23. создайте ее заново но уже с явным указанием имени схемы testnm
    ```
    testdb=# CREATE TABLE testnm.t1(c1 integer);
    CREATE TABLE
24. вставьте строку со значением c1=1
    ```
    testdb=# INSERT INTO testnm.t1 values(1);
    INSERT 0 1
25. зайдите под пользователем testread в базу данных testdb
    ```
    testdb=# \q
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=>    
26. сделайте select * from testnm.t1;
    ```
    testdb=> select * from testnm.t1;
    ERROR:  permission denied for schema testnm
    LINE 1: select * from testnm.t1;
                          ^
    testdb=>
27. получилось?
    - Нет
28. есть идеи почему? если нет - смотрите шпаргалку
    - Пересоздали таблицу t1. Доступ пропал.
    ```
    testdb=> \dt+
    Did not find any relations.
29. как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку
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
30. сделайте select * from testnm.t1;
    ```
    testdb=# \q
    postgres@a20042f3d60a:/$ psql -h 127.0.0.1 -U testread -d testdb -W
    Password: 
    psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    testdb=> select * from testnm.t1;
    ERROR:  permission denied for table t1
31. получилось?
    - Нет
32. есть идеи почему? если нет - смотрите шпаргалку
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
33. сделайте select * from testnm.t1;
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
34. получилось?
    - Да
35. ура!
36. теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
    ```
    testdb=> create table t2(c1 integer); insert into t2 values (2);
    CREATE TABLE
    INSERT 0 1
    testdb=> select * from t2;
     c1 
    ----
      2
    (1 row)
    
37. а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
    - схема по умочанию public. Роль public дается все пользователям.
    ```
    testdb=> select * from public.t2;
     c1 
    ----
      2
    (1 row) 
38. есть идеи как убрать эти права? если нет - смотрите шпаргалку
39. если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды
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

40. теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
расскажите что получилось и почему
    ```
    testdb=> create table t3(c1 integer);
    ERROR:  permission denied for schema public
    LINE 1: create table t3(c1 integer);
                         ^
    testdb=>
    ```
    - Мы отозвали права для создания в схеме public.

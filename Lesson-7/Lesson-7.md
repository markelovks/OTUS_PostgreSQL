# MVCC, vacuum и autovacuum. 
## Домашнее задание.
1. - Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
   - Установить на него PostgreSQL 15 с дефолтными настройками
     - Создал VM. 2 cpu, 4GB ram  
     - Установка PostgresSQL 15.
      ```
       sudo apt update \
        && sudo apt install -y curl ca-certificates lsb-release \
        && sudo mkdir -p /usr/share/postgresql-common/pgdg \
        && sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        &&  sudo install -d /usr/share/postgresql-common/pgdg \
        &&  sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
        && sudo apt update \
        && sudo apt -y install postgresql-15
      ```
      ```
      user7@pc7:~$ sudo pg_ctlcluster 15 main status
      pg_ctl: server is running (PID: 5018)
      /usr/lib/postgresql/15/bin/postgres "-D" "/var/lib/postgresql/15/main" "-c" "config_file=/etc/postgresql/15/main/postgresql.conf"
      ```
2. Создать БД для тестов: выполнить pgbench -i postgres
   ```
   postgres@pc7:/home/user7$ pgbench -i postgres
   dropping old tables...
   NOTICE:  table "pgbench_accounts" does not exist, skipping
   NOTICE:  table "pgbench_branches" does not exist, skipping
   NOTICE:  table "pgbench_history" does not exist, skipping
   NOTICE:  table "pgbench_tellers" does not exist, skipping
   creating tables...
   generating data (client-side)...
   100000 of 100000 tuples (100%) done (elapsed 0.07 s, remaining 0.00 s)
   vacuuming...
   creating primary keys...
   done in 0.30 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.11 s, vacuum 0.04 s, primary keys 0.13 s).
   ```
3. Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
   ```
   postgres@pc7:/home/user7$ pgbench -c8 -P 6 -T 60 -U postgres postgres
   pgbench (15.12 (Ubuntu 15.12-1.pgdg24.04+1))
   starting vacuum...end.
   progress: 6.0 s, 716.5 tps, lat 11.121 ms stddev 7.256, 0 failed
   progress: 12.0 s, 696.8 tps, lat 11.485 ms stddev 7.424, 0 failed
   progress: 18.0 s, 657.8 tps, lat 12.126 ms stddev 8.109, 0 failed
   progress: 24.0 s, 501.2 tps, lat 15.999 ms stddev 12.549, 0 failed
   progress: 30.0 s, 620.2 tps, lat 12.892 ms stddev 8.557, 0 failed
   progress: 36.0 s, 692.8 tps, lat 11.554 ms stddev 7.552, 0 failed
   progress: 42.0 s, 714.8 tps, lat 11.189 ms stddev 7.576, 0 failed
   progress: 48.0 s, 718.0 tps, lat 11.140 ms stddev 7.581, 0 failed
   progress: 54.0 s, 674.2 tps, lat 11.820 ms stddev 8.866, 0 failed
   progress: 60.0 s, 720.3 tps, lat 11.145 ms stddev 7.808, 0 failed
   transaction type: <builtin: TPC-B (sort of)>
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 60 s
   number of transactions actually processed: 40284
   number of failed transactions: 0 (0.000%)
   latency average = 11.913 ms
   latency stddev = 8.397 ms
   initial connection time = 12.696 ms
   tps = 671.303903 (without initial connection time)
   ```
4. Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла.
   ```
   postgres=# ALTER SYSTEM SET shared_buffers TO '1GB';
   ALTER SYSTEM SET effective_cache_size TO '3GB';
   ALTER SYSTEM SET maintenance_work_mem TO '512MB';
   ALTER SYSTEM SET checkpoint_completion_target TO '0.9';
   ALTER SYSTEM SET wal_buffers TO '16MB';
   ALTER SYSTEM SET default_statistics_target TO '500';
   ALTER SYSTEM SET random_page_cost TO '4';
   ALTER SYSTEM SET effective_io_concurrency TO '2';
   ALTER SYSTEM SET work_mem TO '6553kB';
   ALTER SYSTEM SET min_wal_size TO '4GB';
   ALTER SYSTEM SET max_wal_size TO '16GB';
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   ALTER SYSTEM
   postgres=# SELECT pg_reload_conf();
    pg_reload_conf 
   ----------------
    t
   (1 row)
   
   postgres=#
   ```
5. Протестировать заново
   ```
   postgres@pc7:/home/user7$ pgbench -c8 -P 6 -T 60 -U postgres postgres
   pgbench (15.12 (Ubuntu 15.12-1.pgdg24.04+1))
   starting vacuum...end.
   progress: 6.0 s, 731.2 tps, lat 10.879 ms stddev 7.160, 0 failed
   progress: 12.0 s, 722.5 tps, lat 11.079 ms stddev 7.227, 0 failed
   progress: 18.0 s, 656.5 tps, lat 12.182 ms stddev 8.672, 0 failed
   progress: 24.0 s, 714.8 tps, lat 11.187 ms stddev 7.520, 0 failed
   progress: 30.0 s, 722.7 tps, lat 11.068 ms stddev 7.081, 0 failed
   progress: 36.0 s, 728.3 tps, lat 10.982 ms stddev 7.501, 0 failed
   progress: 42.0 s, 722.2 tps, lat 11.079 ms stddev 7.493, 0 failed
   progress: 48.0 s, 718.8 tps, lat 11.127 ms stddev 7.384, 0 failed
   progress: 54.0 s, 686.7 tps, lat 11.640 ms stddev 8.044, 0 failed
   progress: 60.0 s, 669.0 tps, lat 11.961 ms stddev 11.534, 0 failed
   transaction type: <builtin: TPC-B (sort of)>
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 60 s
   number of transactions actually processed: 42444
   number of failed transactions: 0 (0.000%)
   latency average = 11.304 ms
   latency stddev = 8.036 ms
   initial connection time = 23.525 ms
   tps = 707.483070 (without initial connection time)
6. Что изменилось и почему?
   - tps увеличился. \
   Основные изменения это увеличение использование памяти и параметр max_wal_size. Увеличение этого параметра может привести к увеличению времени, которое потребуется для восстановления после сбоя, но позволяет реже выполнять операцию сбрасывания на диск.
7. Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк.
   ```
   postgres=#    CREATE TABLE lesson7(
       id serial,
       text varchar(1000)
     );
   CREATE TABLE
   postgres=#INSERT INTO lesson7(text) SELECT substr(md5(random()::text), 1, 30) FROM generate_series(1, 1000000);
   INSERT 0 1000000
8. Посмотреть размер файла с таблицей
   ```
   postgres=# select count(*) from lesson7;
     count  
   ---------
    1000000
   (1 row)
   
   postgres=# SELECT pg_size_pretty(pg_total_relation_size('lesson7'));
    pg_size_pretty 
   ----------------
    65 MB
   (1 row)
   
   postgres=#
9. 5 раз обновить все строчки и добавить к каждой строчке любой символ
    - Создам процедуру:
      ```
      create or replace procedure update_5()
      LANGUAGE plpgsql
      AS $$
      BEGIN
          FOR i IN 1..5 LOOP
              RAISE NOTICE 'insert LOOP - %', i;
              UPDATE lesson7 SET text = concat(text ,substr(md5(random()::text), 1, 1)) FROM generate_series(1, 1);
          end loop;
      END;
      $$;
      ```
    - Выполним:
      ```
      postgres=# select * from lesson7 limit 5;                                                                     
       id |              text              
      ----+--------------------------------
        1 | 6f21a880696375e5160f3f0c7eaaa9
        2 | 9cecc5554eb3aacf1c849049a568dd
        3 | d051607b302577724e95dc2396db90
        4 | 485d5e62d766703e7d6b8a08f1cf11
        5 | 937b53173526e24b1fa58c3727cf1d
      (5 rows)
      
      postgres=# call update_5();
      NOTICE:  insert LOOP - 1
      NOTICE:  insert LOOP - 2
      NOTICE:  insert LOOP - 3
      NOTICE:  insert LOOP - 4
      NOTICE:  insert LOOP - 5
      CALL
      

      postgres=# select * from lesson7 limit 5;
       id |                text                 
      ----+-------------------------------------
        1 | 6f21a880696375e5160f3f0c7eaaa90f804
        2 | 9cecc5554eb3aacf1c849049a568ddeda80
        3 | d051607b302577724e95dc2396db9037456
        4 | 485d5e62d766703e7d6b8a08f1cf114f872
        5 | 937b53173526e24b1fa58c3727cf1d48825
      (5 rows)
    ```
10. Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
    ```
    postgres=# SELECT CURRENT_TIME;                                                                               
        current_time    
    --------------------
     06:57:38.146794+00
    (1 row)
    
    postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'lesson7';
     relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
    ---------+------------+------------+--------+-------------------------------
     lesson7 |    1000000 |    5000000 |    499 | 2025-03-19 06:57:27.206158+00
    (1 row)
    
    ```
11. Подождать некоторое время, проверяя, пришел ли автовакуум
    ```
    postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'lesson7';
     relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
    ---------+------------+------------+--------+-------------------------------
     lesson7 |    1000000 |          0 |      0 | 2025-03-19 06:58:33.040275+00
    (1 row)
    
    postgres=# 
    ```
12. 5 раз обновить все строчки и добавить к каждой строчке любой символ.
    ```
    postgres=# call update_5();
    CALL
    ```
13. Посмотреть размер файла с таблицей
    ```
    postgres=# SELECT pg_size_pretty(pg_total_relation_size('lesson7'));
     pg_size_pretty 
    ----------------
     430 MB
    (1 row)
    ```
14. Отключить Автовакуум на конкретной таблице
    ```
    postgres=# ALTER TABLE lesson7 SET (autovacuum_enabled = off);
    ALTER TABLE
    postgres=# SELECT relname, reloptions FROM pg_class WHERE relname='lesson7';
     relname |        reloptions        
    ---------+--------------------------
     lesson7 | {autovacuum_enabled=off}
    (1 row)
    ```
15. 10 раз обновить все строчки и добавить к каждой строчке любой символ \
    Посмотреть размер файла с таблицей
    - Создам процедуру:
      ```
      create or replace procedure update_10()
      LANGUAGE plpgsql
      AS $$
      BEGIN
          FOR i IN 1..10 LOOP
              RAISE NOTICE 'insert LOOP - %', i;
              UPDATE lesson7 SET text = concat(text ,substr(md5(random()::text), 1, 1)) FROM generate_series(1, 1);
          end loop;
      END;
      $$;
      ```
      ```
      postgres=# call update_10();
      NOTICE:  insert LOOP - 1
      NOTICE:  insert LOOP - 2
      NOTICE:  insert LOOP - 3
      NOTICE:  insert LOOP - 4
      NOTICE:  insert LOOP - 5
      NOTICE:  insert LOOP - 6
      NOTICE:  insert LOOP - 7
      NOTICE:  insert LOOP - 8
      NOTICE:  insert LOOP - 9
      NOTICE:  insert LOOP - 10
      CALL
      postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'lesson7';
       relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
      ---------+------------+------------+--------+-------------------------------
       lesson7 |    1000000 |   10000000 |    999 | 2025-03-19 07:29:35.069092+00
      (1 row)
      
      postgres=# SELECT pg_size_pretty(pg_total_relation_size('lesson7'));
       pg_size_pretty 
      ----------------
       856 MB
      (1 row)
16. Объясните полученный результат \
Не забудьте включить автовакуум)
    - Размер данных примерно 65-70мб. При грубом подсчете, при работе процедуры 4 цикла перезаписали нули в базе, и 6 циклов расширили таблицу.
    ```
    postgres=# ALTER TABLE lesson7 SET (autovacuum_enabled = on);
    ALTER TABLE
    
    postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'lesson7';
     relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
    ---------+------------+------------+--------+-------------------------------
     lesson7 |    1000000 |          0 |      0 | 2025-03-19 09:31:30.183292+00
    (1 row)

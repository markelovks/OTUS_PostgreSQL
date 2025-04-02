# Журналы. 
## Домашнее задание.
1. Настройте выполнение контрольной точки раз в 30 секунд.
   ```
    postgres=# ALTER SYSTEM SET checkpoint_timeout = '30s';
    ALTER SYSTEM
    postgres=# SELECT pg_reload_conf();
     pg_reload_conf 
    ----------------
     t
    (1 row)
    
2. 10 минут c помощью утилиты pgbench подавайте нагрузку. \
   Измерьте, какой объем журнальных файлов был сгенерирован за это время. 
    - Сбросим статистику
    ```
    postgres=# SELECT pg_stat_reset_shared('bgwriter');
     pg_stat_reset_shared
    ----------------------
    
    (1 row)
    ```
    ```
    CREATE DATABASE lesson8;
    pgbench -i lesson8
    ```
    ```
    postgres@pc7:/home/user7$ pgbench -c8 -P 60 -T 600 -U postgres lesson8
    pgbench (15.12 (Ubuntu 15.12-1.pgdg24.04+1))
    starting vacuum...end.
    progress: 60.0 s, 725.1 tps, lat 11.025 ms stddev 7.586, 0 failed
    progress: 120.0 s, 571.9 tps, lat 13.985 ms stddev 9.967, 0 failed
    progress: 180.0 s, 548.2 tps, lat 14.589 ms stddev 10.119, 0 failed
    progress: 240.0 s, 562.2 tps, lat 14.228 ms stddev 9.895, 0 failed
    progress: 300.0 s, 559.6 tps, lat 14.293 ms stddev 9.924, 0 failed
    progress: 360.0 s, 555.7 tps, lat 14.393 ms stddev 9.997, 0 failed
    progress: 420.0 s, 555.9 tps, lat 14.389 ms stddev 9.944, 0 failed
    progress: 480.0 s, 609.1 tps, lat 13.132 ms stddev 9.370, 0 failed
    progress: 540.0 s, 707.4 tps, lat 11.307 ms stddev 7.705, 0 failed
    progress: 600.0 s, 712.3 tps, lat 11.229 ms stddev 7.797, 0 failed
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 1
    query mode: simple
    number of clients: 8
    number of threads: 1
    maximum number of tries: 1
    duration: 600 s
    number of transactions actually processed: 366452
    number of failed transactions: 0 (0.000%)
    latency average = 13.096 ms
    latency stddev = 9.290 ms
    initial connection time = 18.604 ms
    tps = 610.756189 (without initial connection time)
    ```
    ```
    postgres=# SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;
     checkpoints_timed | checkpoints_req
    -------------------+-----------------
                    53 |               0
    (1 row)
    
    postgres=#
    ```
    - По статистике видно, что все чек поинты выполнились.
    - Посмотрим настройки:
      ```
      postgres=# select name, setting, unit
      from pg_settings
      where name in ('min_wal_size', 'max_wal_size', 'wal_segment_size');
             name       | setting  | unit
      ------------------+----------+------
       max_wal_size     | 1024     | MB
       min_wal_size     | 100      | MB
       wal_segment_size | 16777216 | B
      (3 rows)
      ```
    - Уменьшим min_wal_size, max_wal_size
      ```
      postgres=# ALTER SYSTEM SET min_wal_size = '16MB';
      ALTER SYSTEM
      postgres=# ALTER SYSTEM SET max_wal_size = '32MB';
      ALTER SYSTEM
      postgres=# SELECT pg_reload_conf();
       pg_reload_conf
      ----------------
       t
      (1 row)
      
      postgres=# select name, setting, unit
      from pg_settings
      where name in ('min_wal_size', 'max_wal_size', 'wal_segment_size');
             name       | setting  | unit
      ------------------+----------+------
       max_wal_size     | 32       | MB
       min_wal_size     | 16       | MB
       wal_segment_size | 16777216 | B
      (3 rows)
  
      
      ```
    - Запустим тест еще раз
      ```
      postgres=# SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter; 
       checkpoints_timed | checkpoints_req 
      -------------------+-----------------
                       6 |              58
      (1 row)
      
      ```
    - Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло? \
      Контрольные точки накладывались друг на друга. Так часто (30 сек) нет смысла делать контрольные точки.
    - Оцените, какой объем приходится в среднем на одну контрольную точку. \
      ~155mb
      ```
      postgres=# SELECT pg_size_pretty('1/65EC0AB8'::pg_lsn - '1/2BDFD168'::pg_lsn);
      pg_size_pretty 
      ----------------
       929 MB
      (1 row)
      ```

3. Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.
    ```
    postgres=# ALTER SYSTEM SET synchronous_commit = off;
    ALTER SYSTEM                                                                                                                                                                                          postgres=# SELECT pg_reload_conf();
     pg_reload_conf
    ----------------
     t
    (1 row)
    ```
    - tps = 634.817819 (without initial connection time) \
    tps = 3497.481660 (without initial connection time) \
    Равница в 5 раз. Сбрасывание на диск происходит по расписанию и пачками.
4. Создайте новый кластер с включенной контрольной суммой страниц.
    ```
    user7@pc7:~$ sudo pg_createcluster 15 lesson8 -p 5433 -- --data-checksums
    Creating new PostgreSQL cluster 15/lesson8 ...
    /usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/lesson8 --auth-local peer --auth-host scram-sha-256 --no-instructions --data-checksums
    The files belonging to this database system will be owned by user "postgres".
    This user must also own the server process.
    
    The database cluster will be initialized with locale "C.UTF-8".
    The default database encoding has accordingly been set to "UTF8".
    The default text search configuration will be set to "english".
    
    Data page checksums are enabled.
    
    fixing permissions on existing directory /var/lib/postgresql/15/lesson8 ... ok
    creating subdirectories ... ok
    selecting dynamic shared memory implementation ... posix
    selecting default max_connections ... 100
    selecting default shared_buffers ... 128MB
    selecting default time zone ... Etc/UTC
    creating configuration files ... ok
    running bootstrap script ... ok
    performing post-bootstrap initialization ... ok
    syncing data to disk ... ok
    Ver Cluster Port Status Owner    Data directory                 Log file
    15  lesson8 5433 down   postgres /var/lib/postgresql/15/lesson8 /var/log/postgresql/postgresql-15-lesson8.log
    user7@pc7:~$ sudo pg_ctlcluster 15 lesson8 start
    user7@pc7:~$ sudo pg_ctlcluster 15 lesson8 status
    pg_ctl: server is running (PID: 3199)
    /usr/lib/postgresql/15/bin/postgres "-D" "/var/lib/postgresql/15/lesson8" "-c" "config_file=/etc/postgresql/15/lesson8/postgresql.conf"
    ```
  - Создайте таблицу. Вставьте несколько значений.
    ```
    postgres@pc7:/home/user7$ psql -p 5433
    could not change directory to "/home/user7": Permission denied
    psql (15.12 (Ubuntu 15.12-1.pgdg24.04+1))
    Type "help" for help.
    
    postgres=# CREATE TABLE lesson8(
           id serial,
           text varchar(1000)
         );
    CREATE TABLE
    postgres=# INSERT INTO lesson8(text) SELECT substr(md5(random()::text), 1, 30) FROM generate_series(1, 100);
    INSERT 0 100
    postgres=# select * from lesson8 limit 5;
     id |              text              
    ----+--------------------------------
      1 | 42c6b94a46f4b7360a4555b8629381
      2 | f6cc713d3c76b6952ca4ce32c0a81d
      3 | 2af16bdb8a8dd1a23fee8bd1eb73cb
      4 | 7c344ca078bca433fe00024ea04f53
      5 | 6005f97de4a0f94c954315c57a70a1
    (5 rows)
    
    postgres=# SELECT pg_relation_filepath('lesson8');
     pg_relation_filepath 
    ----------------------
     base/5/16389
    (1 row)
    
    postgres=#
    ```
  - Выключите кластер.
    ```
    user7@pc7:~$ sudo pg_ctlcluster 15 lesson8 stop
    user7@pc7:~$ sudo pg_ctlcluster 15 lesson8 status
    pg_ctl: no server running
    ```
  - Измените пару байт в таблице.
    - В текстовом редакторе поменял значения в файле /var/lib/postgresql/15/lesson8/base/5/16389.
  - Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?
    ```
    user7@pc7:~$ sudo pg_ctlcluster 15 lesson8 start
    user7@pc7:~$ sudo pg_ctlcluster 15 lesson8 status
    pg_ctl: server is running (PID: 3354)
    /usr/lib/postgresql/15/bin/postgres "-D" "/var/lib/postgresql/15/lesson8" "-c" "config_file=/etc/postgresql/15/lesson8/postgresql.conf"
    
    postgres=# select * from lesson8;
    FATAL:  terminating connection due to administrator command
    server closed the connection unexpectedly
            This probably means the server terminated abnormally
            before or while processing the request.
    The connection to the server was lost. Attempting reset: Succeeded.
    postgres=# select * from lesson8;
    WARNING:  page verification failed, calculated checksum 61986 but expected 57725
    ERROR:  invalid page in block 0 of relation base/5/16389
    ```
    - 'Data page checksums' гарантирует целостность, ругается о том что файл был изменен и не совпадает контрольная сумма.
    - Включим 'zero_damaged_pages'
      ```
      postgres=# ALTER SYSTEM SET zero_damaged_pages = on;
      ALTER SYSTEM
      
      postgres=# SELECT pg_reload_conf();
       pg_reload_conf 
      ----------------
       t
      (1 row)
      
      postgres=# show zero_damaged_pages;
       zero_damaged_pages 
      --------------------
       on
      (1 row)
      
      postgres=# select * from lesson8;
      WARNING:  page verification failed, calculated checksum 61986 but expected 57725
      WARNING:  invalid page in block 0 of relation base/5/16389; zeroing out page
       id | text 
      ----+------
      (0 rows)
      
      postgres=#
    
      ```
    - Данные будут заполнены нулями.




   
# Нагрузочное тестирование и тюнинг PostgreSQL. 
## Домашнее задание.
1. развернуть виртуальную машину любым удобным способом

    - Создал VM. 4 cpu, 4GB ram  \

2. поставить на неё PostgreSQL 15 любым способом

    - Установка PostgresSQL 15.
      ```
       sudo apt update \
        && sudo apt install -y curl ca-certificates lsb-release \
        && sudo mkdir -p /usr/share/postgresql-common/pgdg
        && sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        &&  sudo install -d /usr/share/postgresql-common/pgdg \
        &&  sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
        && sudo apt update \
        && sudo apt -y install postgresql-15 \

      ```
      user7@user7-ub1:~$ sudo pg_ctlcluster 15 main status
      pg_ctl: server is running (PID: 5711)
      /usr/lib/postgresql/15/bin/postgres "-D" "/var/lib/postgresql/15/main" "-c" "config_file=/etc/postgresql/15/main/postgresql.conf"
      
3. настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины
нагрузить кластер через утилиту через утилиту pgbench (https://postgrespro.ru/docs/postgrespro/14/pgbench) 

    - Параметры pgbench \
      pgbench -c 50 -j 4 -P 10 -T 60 \
      подключений 50 \
      потоков 4
    - Посмотрим параметр max_wal_size.   
      ```
      postgres=# select * from pg_file_settings where name='max_wal_size';
      -[ RECORD 1 ]---------------------------------------
      sourcefile | /etc/postgresql/15/main/postgresql.conf
      sourceline | 241
      seqno      | 13
      name       | max_wal_size
      setting    | 1GB
      applied    | t
      error      |
      ```
    - Запустил тест pgbench на дефолтных настройках.
      ```
      postgres@user7-ub1:/home/user7$ pgbench -c 50 -j 4 -P 10 -T 60
      pgbench (15.11 (Ubuntu 15.11-1.pgdg24.04+1))
      starting vacuum...end.
      progress: 10.0 s, 466.8 tps, lat 105.018 ms stddev 130.186, 0 failed
      progress: 20.0 s, 501.0 tps, lat 99.911 ms stddev 134.128, 0 failed
      progress: 30.0 s, 484.0 tps, lat 103.073 ms stddev 162.233, 0 failed
      progress: 40.0 s, 470.4 tps, lat 106.819 ms stddev 132.849, 0 failed
      progress: 50.0 s, 518.7 tps, lat 96.558 ms stddev 106.991, 0 failed
      progress: 60.0 s, 448.3 tps, lat 110.553 ms stddev 132.299, 0 failed
      transaction type: <builtin: TPC-B (sort of)>
      scaling factor: 1
      query mode: simple
      number of clients: 50
      number of threads: 4
      maximum number of tries: 1
      duration: 60 s
      number of transactions actually processed: 28941
      number of failed transactions: 0 (0.000%)
      latency average = 103.681 ms
      latency stddev = 134.247 ms
      initial connection time = 55.040 ms
      tps = 481.544833 (without initial connection time)
      ```
    
    - Используя pgconfig.org сгенерировал конфиг General web applications. \
      В этом конфиге увеличен параметр max_wal_size. Увеличение этого параметра может привести к увеличению времени, которое потребуется для восстановления после сбоя, но позволяет реже выполнять операцию сбрасывания на диск. \
      Для тестовой среды нам подходит.
      ```
      postgres=# select * from pg_file_settings where name='max_wal_size';
      -[ RECORD 1 ]------------------------------------------------
      sourcefile | /etc/postgresql/15/main/postgresql.conf
      sourceline | 241
      seqno      | 13
      name       | max_wal_size
      setting    | 1GB
      applied    | f
      error      | 
      -[ RECORD 2 ]------------------------------------------------
      sourcefile | /var/lib/postgresql/15/main/postgresql.auto.conf
      sourceline | 8
      seqno      | 30
      name       | max_wal_size
      setting    | 3GB
      applied    | t
      error      | 
      
      postgres=# 
      ```
      ```
      postgres@user7-ub1:/home/user7$ pgbench -c 50 -j 4 -P 10 -T 60
      pgbench (15.11 (Ubuntu 15.11-1.pgdg24.04+1))
      starting vacuum...end.
      progress: 10.0 s, 518.9 tps, lat 94.826 ms stddev 124.561, 0 failed
      progress: 20.0 s, 546.2 tps, lat 91.236 ms stddev 104.298, 0 failed
      progress: 30.0 s, 475.1 tps, lat 105.849 ms stddev 142.871, 0 failed
      progress: 40.0 s, 539.1 tps, lat 92.416 ms stddev 112.425, 0 failed
      progress: 50.0 s, 521.3 tps, lat 96.219 ms stddev 114.720, 0 failed
      progress: 60.0 s, 480.8 tps, lat 104.013 ms stddev 114.345, 0 failed
      transaction type: <builtin: TPC-B (sort of)>
      scaling factor: 1
      query mode: simple
      number of clients: 50
      number of threads: 4
      maximum number of tries: 1
      duration: 60 s
      number of transactions actually processed: 30863
      number of failed transactions: 0 (0.000%)
      latency average = 97.228 ms
      latency stddev = 119.145 ms
      initial connection time = 39.763 ms
      tps = 513.739045 (without initial connection time)
    - Производительность увеличиласть с tps = 481.544833 до tps = 513.739045. \
    Основные изменения это количество соединений и увеличение использование памяти.
    ```
    user7@user7-ub1:~$ sudo cat /var/lib/postgresql/15/main/postgresql.auto.conf
    # Do not edit this file manually!
    # It will be overwritten by the ALTER SYSTEM command.
    shared_buffers = '1GB'
    effective_cache_size = '3GB'
    work_mem = '20MB'
    maintenance_work_mem = '205MB'
    min_wal_size = '2GB'
    max_wal_size = '3GB'
    checkpoint_completion_target = '0.9'
    wal_buffers = '-1'
    listen_addresses = '*'
    max_connections = '50'
    random_page_cost = '1.1'
    effective_io_concurrency = '200'
    max_worker_processes = '8'
    max_parallel_workers_per_gather = '2'
    max_parallel_workers = '2'
    logging_collector = 'on'
    log_checkpoints = 'on'
    log_connections = 'on'
    log_disconnections = 'on'
    log_lock_waits = 'on'
    log_temp_files = '0'
    lc_messages = 'C'
    log_min_duration_statement = '10s'
    log_autovacuum_min_duration = '0'
    log_destination = 'csvlog'

4. Задание со *: аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки
https://github.com/akopytov/sysbench)

    - Установка sysbench
    ```
    curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
    sudo apt -y install sysbench
    ```
    - Установка sysbench-tpcc
    ```
    git clone https://github.com/Percona-Lab/sysbench-tpcc.git
    ``` 
    - Подготовка таблиц
    ```
    postgres=# create database tpcc;
    CREATE DATABASE
    ```
    - Подготовка базы\
      2 warehouse в каждом 2 таблицы \
   Размер базы
   ```
    tpcc      | postgres | UTF8     | C.UTF-8 | C.UTF-8 |            | libc            |                       | 457 MB  | pg_default |
   ```
   - Тест на стандартных настройках \
   ```
   ./tpcc.lua --pgsql-host=localhost --pgsql-user=postgres --pgsql-password=99999 --pgsql-db=tpcc --time=60 --threads=4 --report-interval=10 --tables=2 --scale=2 --db-driver=pgsql run
   sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)
   
   Running the test with following options:
   Number of threads: 4
   Report intermediate results every 10 second(s)
   Initializing random number generator from current time
   
   
   Initializing worker threads...
   
   DB SCHEMA public
   DB SCHEMA public
   DB SCHEMA public
   DB SCHEMA public
   Threads started!
   
   [ 10s ] thds: 4 tps: 302.46 qps: 8879.12 (r/w/o: 4013.97/4174.05/691.11) lat (ms,95%): 28.16 err/s 43.59 reconn/s: 0.00
   [ 20s ] thds: 4 tps: 332.50 qps: 9923.85 (r/w/o: 4507.12/4656.92/759.80) lat (ms,95%): 23.52 err/s 49.90 reconn/s: 0.00
   [ 30s ] thds: 4 tps: 364.70 qps: 11132.28 (r/w/o: 5063.14/5246.34/822.81) lat (ms,95%): 20.00 err/s 48.20 reconn/s: 0.00
   [ 40s ] thds: 4 tps: 396.60 qps: 11639.38 (r/w/o: 5273.55/5466.04/899.79) lat (ms,95%): 20.74 err/s 54.60 reconn/s: 0.00
   [ 50s ] thds: 4 tps: 372.60 qps: 11262.86 (r/w/o: 5120.83/5299.03/843.00) lat (ms,95%): 18.28 err/s 50.30 reconn/s: 0.00
   [ 60s ] thds: 4 tps: 717.05 qps: 21683.99 (r/w/o: 9856.26/10218.63/1609.10) lat (ms,95%): 10.84 err/s 91.29 reconn/s: 0.00
   SQL statistics:
       queries performed:
           read:                            338402
           write:                           350667
           other:                           56262
           total:                           745331
       transactions:                        24864  (414.33 per sec.)
       queries:                             745331 (12420.13 per sec.)
       ignored errors:                      3379   (56.31 per sec.)
       reconnects:                          0      (0.00 per sec.)
   
   General statistics:
       total time:                          60.0086s
       total number of events:              24864
   
   Latency (ms):
            min:                                    0.27
            avg:                                    9.65
            max:                                  351.33
            95th percentile:                       18.61
            sum:                               239971.82
   
   Threads fairness:
       events (avg/stddev):           6216.0000/47.47
       execution time (avg/stddev):   59.9930/0.00
   ```
   - Используя pgconfig.org сгенерировал конфиг General web applications.
   ```
   sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)
   
   Running the test with following options:
   Number of threads: 4
   Report intermediate results every 10 second(s)
   Initializing random number generator from current time
   
   
   Initializing worker threads...
   
   DB SCHEMA public
   DB SCHEMA public
   DB SCHEMA public
   DB SCHEMA public
   Threads started!
   
   [ 10s ] thds: 4 tps: 895.47 qps: 26259.54 (r/w/o: 11927.39/12324.94/2007.21) lat (ms,95%): 9.06 err/s 112.08 reconn/s: 0.00
   [ 20s ] thds: 4 tps: 873.30 qps: 26067.28 (r/w/o: 11839.64/12271.34/1956.31) lat (ms,95%): 9.56 err/s 109.10 reconn/s: 0.00
   [ 30s ] thds: 4 tps: 835.43 qps: 24932.78 (r/w/o: 11318.89/11721.66/1892.23) lat (ms,95%): 9.91 err/s 114.49 reconn/s: 0.00
   [ 40s ] thds: 4 tps: 673.42 qps: 20219.26 (r/w/o: 9187.56/9533.27/1498.44) lat (ms,95%): 12.52 err/s 78.80 reconn/s: 0.00
   [ 50s ] thds: 4 tps: 617.60 qps: 18180.83 (r/w/o: 8247.06/8545.56/1388.21) lat (ms,95%): 14.46 err/s 79.90 reconn/s: 0.00
   [ 60s ] thds: 4 tps: 511.12 qps: 15002.17 (r/w/o: 6803.40/7058.56/1140.22) lat (ms,95%): 17.95 err/s 61.29 reconn/s: 0.00
   SQL statistics:
       queries performed:
           read:                            593288
           write:                           614605
           other:                           98836
           total:                           1306729
       transactions:                        44070  (734.12 per sec.)
       queries:                             1306729 (21767.59 per sec.)
       ignored errors:                      5557   (92.57 per sec.)
       reconnects:                          0      (0.00 per sec.)
   
   General statistics:
       total time:                          60.0290s
       total number of events:              44070
   
   Latency (ms):
            min:                                    0.25
            avg:                                    5.45
            max:                                   72.03
            95th percentile:                       12.30
            sum:                               239962.90
   
   Threads fairness:
       events (avg/stddev):           11017.5000/103.50
       execution time (avg/stddev):   59.9907/0.01
   
   ```
   - Производительность увеличиласть с \
     transactions:                        24864  (414.33 per sec.) \
     до \
     transactions:                        44070  (734.12 per sec.)


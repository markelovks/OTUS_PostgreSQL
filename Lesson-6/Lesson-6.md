# Механизм блокировок. 
## Домашнее задание.
1. Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.

    - Создал VM. 4 cpu, 4GB ram  
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
      ```
      user7@user7-ub1:~$ sudo pg_ctlcluster 15 main status
      pg_ctl: server is running (PID: 874)
      /usr/lib/postgresql/15/bin/postgres "-D" "/var/lib/postgresql/15/main" "-c" "config_file=/etc/postgresql/15/main/postgresql.conf"
      ```
    - Настройка PostgresSQL
      ```
      postgres=# ALTER SYSTEM SET log_lock_waits = on;
            ALTER SYSTEM SET deadlock_timeout = 200;
            SELECT pg_reload_conf();
            SHOW deadlock_timeout;
      ALTER SYSTEM
      ALTER SYSTEM
       pg_reload_conf 
      ----------------
       t
      (1 row)
      
       deadlock_timeout 
      ------------------
       200ms
      (1 row)
      ```
    - Создаем базу и таблицы для теста
      ```
      postgres=# CREATE DATABASE locks;
      CREATE DATABASE
      postgres=# \c locks
      You are now connected to database "locks" as user "postgres".
      locks=# CREATE TABLE accounts(
        acc_no integer PRIMARY KEY,
        amount numeric
      );
      INSERT INTO accounts VALUES (1,1000.00), (2,2000.00), (3,3000.00);
      CREATE TABLE
      INSERT 0 3
    - Тест
      - Session #1
        ```
        locks=# BEGIN;                                                                             
        BEGIN
        locks=*# UPDATE accounts SET amount = amount + 100 WHERE acc_no = 1;
        UPDATE 1
        locks=*#
        ```
      - Session #2
        ```
        locks=# BEGIN;
        BEGIN
        locks=*# UPDATE accounts SET amount = amount + 200 WHERE acc_no = 1;
        ```
      - Session #2 Подвисает.
      - Сообщение лога:
        ```
        2025-03-10 12:08:50.208 UTC,"postgres","locks",2458,"[local]",67ced21c.99a,4,"UPDATE waiting",2025-03-10 11:50:52 UTC,5/316,504815,LOG,00000,"process 2458 still waiting for ShareLock on transaction 504814 after 200.126 ms","Process holding the lock: 2249. Wait queue: 2458.",,,,"while updating tuple (0,4) in relation ""accounts""","UPDATE accounts SET amount = amount + 200 WHERE acc_no = 1;",,,"psql","client backend",,0
        ```
      - Сообщения лога после COMMIT;
        ```
        2025-03-10 12:10:45.639 UTC,"postgres","locks",2458,"[local]",67ced21c.99a,5,"UPDATE waiting",2025-03-10 11:50:52 UTC,5/316,504815,LOG,00000,"process 2458 acquired ShareLock on transaction 504814 after 115630.818 ms",,,,,"while updating tuple (0,4) in relation ""accounts""","UPDATE accounts SET amount = amount + 200 WHERE acc_no = 1;",,,"psql","client backend",,0
        2025-03-10 12:10:45.639 UTC,"postgres","locks",2458,"[local]",67ced21c.99a,6,"UPDATE",2025-03-10 11:50:52 UTC,5/316,504815,LOG,00000,"duration: 115631.558 ms  statement: UPDATE accounts SET amount = amount + 200 WHERE acc_no = 1;",,,,,,,,,"psql","client backend",,0
        ```

2. Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.
    - Запустил 3 сеанса. \
      SELECT pg_backend_pid();
      - Session #1 PID - 2458
        ```
        locks=# SELECT pg_backend_pid();
         pg_backend_pid
        ----------------
                   2458
        (1 row)
        locks=# BEGIN;
        BEGIN
        locks=*# UPDATE accounts SET amount = amount + 100 WHERE acc_no = 1;
        UPDATE 1
        locks=*#  
        ```  
      - Session #2 PID - 2249
        ```
        locks=# SELECT pg_backend_pid();
         pg_backend_pid
        ----------------
                   2249
        (1 row)
        
        locks=# BEGIN;
        BEGIN
        locks=*# UPDATE accounts SET amount = amount + 200 WHERE acc_no = 1;
        ``` 
      - Session #3 PID - 2494
        ```
        locks=# SELECT pg_backend_pid();
         pg_backend_pid
        ----------------
                   2494
        (1 row)
        
        locks=# BEGIN;
        BEGIN
        locks=*# UPDATE accounts SET amount = amount + 300 WHERE acc_no = 1
        ``` 
    - Список блокировок
      - Смотрим Session #1 PID - 2458. \
        Все блокировки получены. (t)
        ```
        postgres=# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted
        FROM pg_locks WHERE pid = 2458;
           locktype    | relation | virtxid |  xid   |       mode       | granted 
        ---------------+----------+---------+--------+------------------+---------
         relation      | 26499    |         |        | RowExclusiveLock | t
         relation      | 26497    |         |        | RowExclusiveLock | t
         relation      | 26492    |         |        | RowExclusiveLock | t
         virtualxid    |          | 5/319   |        | ExclusiveLock    | t
         transactionid |          |         | 504816 | ExclusiveLock    | t
        (5 rows)
                
        ```
      - Смотрим Session #2 PID - 2249. \
        Не может получить блокировку в режиме ShareLock. \
        Видим, что блокирует Session #1 (2458)
        ```
        postgres=# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted
        FROM pg_locks WHERE pid = 2249;
           locktype    | relation | virtxid |  xid   |       mode       | granted 
        ---------------+----------+---------+--------+------------------+---------
         relation      | 26499    |         |        | RowExclusiveLock | t
         relation      | 26497    |         |        | RowExclusiveLock | t
         relation      | 26492    |         |        | RowExclusiveLock | t
         virtualxid    |          | 3/40    |        | ExclusiveLock    | t
         tuple         | 26492    |         |        | ExclusiveLock    | t
         transactionid |          |         | 504816 | ShareLock        | f
         transactionid |          |         | 504817 | ExclusiveLock    | t
        (7 rows)
        
        postgres=# SELECT * FROM pg_stat_activity WHERE pid = ANY(pg_blocking_pids(2249)) \gx
        -[ RECORD 1 ]----+------------------------------------------------------------
        datid            | 26477
        datname          | locks
        pid              | 2458
        leader_pid       | 
        usesysid         | 10
        usename          | postgres
        application_name | psql
        client_addr      | 
        client_hostname  | 
        client_port      | -1
        backend_start    | 2025-03-10 11:50:52.588055+00
        xact_start       | 2025-03-10 12:20:25.607989+00
        query_start      | 2025-03-10 12:20:29.186386+00
        state_change     | 2025-03-10 12:20:29.186599+00
        wait_event_type  | Client
        wait_event       | ClientRead
        state            | idle in transaction
        backend_xid      | 504816
        backend_xmin     | 
        query_id         | 
        query            | UPDATE accounts SET amount = amount + 100 WHERE acc_no = 1;
        backend_type     | client backend
        
        postgres=# 
        ```
      - Смотрим Session #3 PID - 2494. \
        Не может получить блокировку в режиме ExclusiveLock. \
        Видим, что блокирует Session #2 (2249)
        ```
        postgres=# SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted
        FROM pg_locks WHERE pid = 2494;
           locktype    | relation | virtxid |  xid   |       mode       | granted 
        ---------------+----------+---------+--------+------------------+---------
         relation      | 26499    |         |        | RowExclusiveLock | t
         relation      | 26497    |         |        | RowExclusiveLock | t
         relation      | 26492    |         |        | RowExclusiveLock | t
         virtualxid    |          | 6/8     |        | ExclusiveLock    | t
         tuple         | 26492    |         |        | ExclusiveLock    | f
         transactionid |          |         | 504818 | ExclusiveLock    | t
        (6 rows)
        
        postgres=# SELECT * FROM pg_stat_activity WHERE pid = ANY(pg_blocking_pids(2494)) \gx
        -[ RECORD 1 ]----+------------------------------------------------------------
        datid            | 26477
        datname          | locks
        pid              | 2249
        leader_pid       | 
        usesysid         | 10
        usename          | postgres
        application_name | psql
        client_addr      | 
        client_hostname  | 
        client_port      | -1
        backend_start    | 2025-03-10 10:57:36.345526+00
        xact_start       | 2025-03-10 12:21:59.387216+00
        query_start      | 2025-03-10 12:22:06.681816+00
        state_change     | 2025-03-10 12:22:06.681818+00
        wait_event_type  | Lock
        wait_event       | transactionid
        state            | active
        backend_xid      | 504817
        backend_xmin     | 504816
        query_id         | 
        query            | UPDATE accounts SET amount = amount + 200 WHERE acc_no = 1;
        backend_type     | client backend
        
        postgres=#
        ```

3. Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?
    - Возьмем пример из уроков.
      - Session #1 - PID 12590
      ```
      BEGIN;
      UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;
      ```
      - Session #2 - PID 12583
      ```
      BEGIN;
      UPDATE accounts SET amount = amount + 200.00 WHERE acc_no = 2;
      ``` 
      - Session #3 - PID 12592
      ```
      BEGIN;
      UPDATE accounts SET amount = amount + 300.00 WHERE acc_no = 3;
      ``` 
      - Session #1
      ```
      UPDATE accounts SET amount = amount + 102.00 WHERE acc_no = 2;
      ``` 
      - Session #2
      ```
      UPDATE accounts SET amount = amount + 103.00 WHERE acc_no = 3;
      ``` 
      - Session #3
      ```
      UPDATE accounts SET amount = amount + 101.00 WHERE acc_no = 1;
      ``` 
      - Логи
      ```
      2025-03-11 07:09:58.412 UTC,"postgres","locks",12592,"[local]",67cfe0e3.3130,6,"UPDATE",2025-03-11 07:06:11 UTC,4/10,504826,ERROR,40P01,"deadlock detected","Process 12592 waits for ShareLock on transaction 504824; blocked by process 12590.
      Process 12590 waits for ShareLock on transaction 504825; blocked by process 12583.
      Process 12583 waits for ShareLock on transaction 504826; blocked by process 12592.
      Process 12592: UPDATE accounts SET amount = amount + 101.00 WHERE acc_no = 1;
      Process 12590: UPDATE accounts SET amount = amount + 102.00 WHERE acc_no = 2;
      Process 12583: UPDATE accounts SET amount = amount + 103.00 WHERE acc_no = 3;","See server log for query details.",,,"while updating tuple (0,10) in relation ""accounts""","UPDATE accounts SET amount = amount + 101.00 WHERE acc_no = 1;",,,"psql","client backend",,0
      ```
    - Из журнала понятно, что в третьем сеансе PID 12592 обнаружен deadlock. \
    12592(#3) > 12590(#1) > 12583(#2) > 12592(#3)

4. Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?
    - Может. Если используется Уровень изоляции Repeatable Read.
    - Session #1.
      ```
      locks=# BEGIN ISOLATION LEVEL REPEATABLE READ;
      BEGIN
      locks=*# UPDATE accounts SET amount = amount + 100.00;
      UPDATE 3
      ``` 
    - Session #2. Ожидает.
      ```
      locks=# BEGIN ISOLATION LEVEL REPEATABLE READ;
      BEGIN
      locks=*# UPDATE accounts SET amount = amount + 100.00;
      ```
    - Session #1.
      ```
      locks=*# commit;
      COMMIT
      ``` 
    - Session #2. Отвисает с ошибкой.
      ```
      ERROR:  could not serialize access due to concurrent update


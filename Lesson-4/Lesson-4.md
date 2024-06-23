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
теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
есть идеи как убрать эти права? если нет - смотрите шпаргалку
если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды
теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
расскажите что получилось и почему
1. остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop
   - Лучше использовать другую комманду, что-бы systemd не выпадал в ошибку.
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo -u postgres pg_ctlcluster 15 main stop
   Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
     sudo systemctl stop postgresql@15-main

   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo systemctl status postgresql@15-main
   ○ postgresql@15-main.service - PostgreSQL Cluster 15-main
        Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
        Active: inactive (dead) since Mon 2024-04-22 11:10:24 UTC; 5s ago
       Process: 5071 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=0/SUCCESS)
       Process: 5156 ExecStop=/usr/bin/pg_ctlcluster --skip-systemctl-redirect -m fast 15-main stop (code=exited, status=0/SUCCESS)
      Main PID: 5076 (code=exited, status=0/SUCCESS)
           CPU: 588ms
   
   Apr 22 11:01:00 fhmmguqa3s4slar9mj25 systemd[1]: Starting PostgreSQL Cluster 15-main...
   Apr 22 11:01:02 fhmmguqa3s4slar9mj25 systemd[1]: Started PostgreSQL Cluster 15-main.
   Apr 22 11:10:24 fhmmguqa3s4slar9mj25 systemd[1]: Stopping PostgreSQL Cluster 15-main...
   Apr 22 11:10:24 fhmmguqa3s4slar9mj25 systemd[1]: postgresql@15-main.service: Deactivated successfully.
   Apr 22 11:10:24 fhmmguqa3s4slar9mj25 systemd[1]: Stopped PostgreSQL Cluster 15-main.     
2. создайте новый диск к ВМ размером 10GB \
   добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
   ```
   postgre-data Подключен HDD	10 ГБ	Ready postgre-1-ru-central1-a ru-central1-a	22.04.2024, в 14:13	— fhmlbfouljvm2a4ube1s
   ```
   ```
   Disk /dev/vdb: 10 GiB, 10737418240 bytes, 20971520 sectors
   Units: sectors of 1 * 512 = 512 bytes
   Sector size (logical/physical): 512 bytes / 4096 bytes
   I/O size (minimum/optimal): 4096 bytes / 4096 bytes
3. проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo parted /dev/vdb mklabel gpt
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo parted -a opt /dev/vdb mkpart primary ext4 0% 100%
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo mkfs.ext4 -L datapartition /dev/vdb1
   mke2fs 1.46.5 (30-Dec-2021)
   Creating filesystem with 2620928 4k blocks and 655360 inodes
   Filesystem UUID: 94e2f8a7-accf-4d6a-b1ff-ea3bea5da48b
   Superblock backups stored on blocks: 
   	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632
   
   Allocating group tables: done                            
   Writing inode tables: done                            
   Creating journal (16384 blocks): done
   Writing superblocks and filesystem accounting information: done 
   
   ubuntu@fhmmguqa3s4slar9mj25:~$ lsblk -f | grep vdb
   vdb                                                                                     
   └─vdb1 ext4     1.0   datapartition 94e2f8a7-accf-4d6a-b1ff-ea3bea5da48b
   
   echo "/dev/disk/by-uuid/94e2f8a7-accf-4d6a-b1ff-ea3bea5da48b /mnt/data ext4 defaults 0 2" | sudo tee -a /etc/fstab
   
   sudo mkdir /mnt/data
   
   sudo mount -a
   ubuntu@fhmmguqa3s4slar9mj25:~$ df -hT | grep /vdb
   /dev/vdb1      ext4   9.8G   24K  9.3G   1% /mnt/data

4. перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo reboot
   Connection to 158.160.34.98 closed by remote host.
   Connection to 158.160.34.98 closed.
   
   ubuntu@fhmmguqa3s4slar9mj25:~$ df -hT | grep /vdb
   /dev/vdb1      ext4   9.8G   24K  9.3G   1% /mnt/data
5. сделайте пользователя postgres владельцем /mnt/data
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo chown -R postgres:postgres /mnt/data/
   ubuntu@fhmmguqa3s4slar9mj25:~$ ls -llha /mnt/data/
   total 24K
   drwxr-xr-x 3 postgres postgres 4.0K Apr 22 11:27 .
   drwxr-xr-x 3 root     root     4.0K Apr 22 11:36 ..
   drwx------ 2 postgres postgres  16K Apr 22 11:27 lost+found
6.  перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data
    ```
    sudo mv /var/lib/postgresql/15 /mnt/data
7.  попытайтесь запустить кластер
    ```
    ubuntu@fhmmguqa3s4slar9mj25:~$ sudo systemctl start postgresql@15-main
    Job for postgresql@15-main.service failed because the service did not take the steps required by its unit configuration.
    See "systemctl status postgresql@15-main.service" and "journalctl -xeu postgresql@15-main.service" for details.
    
    ubuntu@fhmmguqa3s4slar9mj25:~$ sudo systemctl status postgresql@15-main
    × postgresql@15-main.service - PostgreSQL Cluster 15-main
         Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
         Active: failed (Result: protocol) since Mon 2024-04-22 12:35:04 UTC; 10s ago
        Process: 1530 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=1/FAILURE)
            CPU: 49ms
    
    Apr 22 12:35:04 fhmmguqa3s4slar9mj25 systemd[1]: Starting PostgreSQL Cluster 15-main...
    Apr 22 12:35:04 fhmmguqa3s4slar9mj25 postgresql@15-main[1530]: Error: /var/lib/postgresql/15/main is not accessible or does not exist
    Apr 22 12:35:04 fhmmguqa3s4slar9mj25 systemd[1]: postgresql@15-main.service: Can't open PID file /run/postgresql/15-main.pid (yet?) after start: Operation not permitted
    Apr 22 12:35:04 fhmmguqa3s4slar9mj25 systemd[1]: postgresql@15-main.service: Failed with result 'protocol'.
    Apr 22 12:35:04 fhmmguqa3s4slar9mj25 systemd[1]: Failed to start PostgreSQL Cluster 15-main.

8.  напишите получилось или нет и почему
    - Кластер не запустился, так как не видит файлы рабочие данные в папке /var/lib/postgresql/15/main. Так как папка не существует, после переноса.

9.  задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его
    - Поменять необходимо параметр data_directory в файле /etc/postgresql/15/main/postgresql.conf. Из-за того что мы перенесли файлы. Кластер запустился.
    ```
    sudo sed -i "s|\/var\/lib\/postgresql\/15\/main|\/mnt\/data\/15\/main|g" /etc/postgresql/15/main/postgresql.conf
    ```
    ```
    ubuntu@fhmmguqa3s4slar9mj25:~$ sudo systemctl start postgresql@15-main
    ubuntu@fhmmguqa3s4slar9mj25:~$ sudo systemctl status postgresql@15-main
    ● postgresql@15-main.service - PostgreSQL Cluster 15-main
         Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
         Active: active (running) since Mon 2024-04-22 12:49:41 UTC; 1s ago
        Process: 1688 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=0/SUCCESS)
       Main PID: 1693 (postgres)
          Tasks: 6 (limit: 4558)
         Memory: 18.9M
            CPU: 208ms
         CGroup: /system.slice/system-postgresql.slice/postgresql@15-main.service
                 ├─1693 /usr/lib/postgresql/15/bin/postgres -D /mnt/data/15/main -c config_file=/etc/postgresql/15/main/postgresql.conf
                 ├─1694 "postgres: 15/main: checkpointer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "">
                 ├─1695 "postgres: 15/main: background writer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
                 ├─1697 "postgres: 15/main: walwriter " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "">
                 ├─1698 "postgres: 15/main: autovacuum launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
                 └─1699 "postgres: 15/main: logical replication launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
    
    Apr 22 12:49:38 fhmmguqa3s4slar9mj25 systemd[1]: Starting PostgreSQL Cluster 15-main...
    Apr 22 12:49:38 fhmmguqa3s4slar9mj25 postgresql@15-main[1688]: Removed stale pid file.
    Apr 22 12:49:41 fhmmguqa3s4slar9mj25 systemd[1]: Started PostgreSQL Cluster 15-main.
    
10. зайдите через через psql и проверьте содержимое ранее созданной таблицы
    ```
    ubuntu@fhmmguqa3s4slar9mj25:~$ sudo -u postgres psql
    could not change directory to "/home/ubuntu": Permission denied
    psql (15.6 (Ubuntu 15.6-1.pgdg22.04+1))
    Type "help" for help.
    
    postgres=# select * from test;
     c1 
    ----
     1
    (1 row)
    
    postgres=#
11. задание со звездочкой *: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.
    - Остановил postgres на VM postgre-1-ru-central1-a.
    - Отсоединил диск postgre-data от VM postgre-1-ru-central1-a.
    - Создал новую VM Ubuntu 22.04. postgre-2-ru-central1-a.
    - Подключил к VM postgre-2-ru-central1-a диск postgre-data.
    - Установил postgres.
    - Остановил postgres.
    - Создал папку /mnt/data.
    - Смонтировал диск /dev/vdb1 в /mnt/data через fstab.
    - Изменил параметр data_directory в конфигурационном файле postgresql.conf.
    - Запустил postgres.
      ```
      ubuntu@fhmpjdktqrue2ltfb7d2:~$ sudo systemctl status postgresql@15-main.service 
      ● postgresql@15-main.service - PostgreSQL Cluster 15-main
           Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
           Active: active (running) since Tue 2024-04-23 07:29:04 UTC; 3s ago
          Process: 5524 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=0/SUCCESS)
         Main PID: 5529 (postgres)
            Tasks: 6 (limit: 4558)
           Memory: 19.9M
              CPU: 199ms
           CGroup: /system.slice/system-postgresql.slice/postgresql@15-main.service
                   ├─5529 /usr/lib/postgresql/15/bin/postgres -D /mnt/data/15/main -c config_file=/etc/postgresql/15/main/postgresql.conf
                   ├─5530 "postgres: 15/main: checkpointer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "">
                   ├─5531 "postgres: 15/main: background writer " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
                   ├─5533 "postgres: 15/main: walwriter " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "">
                   ├─5534 "postgres: 15/main: autovacuum launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
                   └─5535 "postgres: 15/main: logical replication launcher " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
      
      Apr 23 07:29:00 fhmpjdktqrue2ltfb7d2 systemd[1]: Starting PostgreSQL Cluster 15-main...
      Apr 23 07:29:04 fhmpjdktqrue2ltfb7d2 systemd[1]: Started PostgreSQL Cluster 15-main.      
    - Проверил данные
      ```  
      ubuntu@fhmpjdktqrue2ltfb7d2:~$ sudo -u postgres psql
      psql (15.6 (Ubuntu 15.6-1.pgdg22.04+1))
      Type "help" for help.
      
      postgres=# select * from 
      information_schema.  public.              test                 
      postgres=# select * from test ;
       c1 
      ----
       1
      (1 row)
      
      postgres=#      

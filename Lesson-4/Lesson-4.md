# Установка PostgreSQL. 
## Домашнее задание.
1. создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере

    - С помощью terraform создал инрфраструктуру в облаке Yandex Cloud. \
      Создано: 
      - облако postgre
      - каталог postgre
      - сеть postgre-network
      - подсеть postgre-ru-central1-a
      - VM postgre-1-ru-central1-a (Ubuntu 22.04 LTS) с публичным ip и metadata с ssh ключом
  
2. поставьте на нее PostgreSQL 15 через sudo apt
   ```
   sudo apt install -y curl ca-certificates \
     && sudo install -d /usr/share/postgresql-common/pgdg \
     && sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
     && sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
     && sudo apt update \
     && sudo apt -y install postgresql-15 \
     && sudo service postgresql start \
     && sudo service postgresql status
3. проверьте что кластер запущен через sudo -u postgres pg_lsclusters
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo -u postgres pg_lsclusters
   Ver Cluster Port Status Owner    Data directory              Log file
   15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
4. зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo -u postgres psql
   psql (15.6 (Ubuntu 15.6-1.pgdg22.04+1))
   Type "help" for help.
   
   postgres=# create table test(c1 text);
   CREATE TABLE
   postgres=# insert into test values('1');
   INSERT 0 1
   postgres=#
   postgres=# select * from test;
    c1 
   ----
    1
   (1 row)
5. остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop
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
6. создайте новый диск к ВМ размером 10GB \
   добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
   ```
   postgre-data Подключен HDD	10 ГБ	Ready postgre-1-ru-central1-a ru-central1-a	22.04.2024, в 14:13	— fhmlbfouljvm2a4ube1s
   ```
   ```
   Disk /dev/vdb: 10 GiB, 10737418240 bytes, 20971520 sectors
   Units: sectors of 1 * 512 = 512 bytes
   Sector size (logical/physical): 512 bytes / 4096 bytes
   I/O size (minimum/optimal): 4096 bytes / 4096 bytes
7. проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
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

8. перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo reboot
   Connection to 158.160.34.98 closed by remote host.
   Connection to 158.160.34.98 closed.
   
   ubuntu@fhmmguqa3s4slar9mj25:~$ df -hT | grep /vdb
   /dev/vdb1      ext4   9.8G   24K  9.3G   1% /mnt/data
9. сделайте пользователя postgres владельцем /mnt/data
   ```
   ubuntu@fhmmguqa3s4slar9mj25:~$ sudo chown -R postgres:postgres /mnt/data/
   ubuntu@fhmmguqa3s4slar9mj25:~$ ls -llha /mnt/data/
   total 24K
   drwxr-xr-x 3 postgres postgres 4.0K Apr 22 11:27 .
   drwxr-xr-x 3 root     root     4.0K Apr 22 11:36 ..
   drwx------ 2 postgres postgres  16K Apr 22 11:27 lost+found
10. перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data
    ```
    sudo mv /var/lib/postgresql/15 /mnt/data
11. попытайтесь запустить кластер
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

12. напишите получилось или нет и почему
    - Кластер не запустился, так как не видит файлы рабочие данные в папке /var/lib/postgresql/15/main. Так как папка не существует, после переноса.

13. задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его
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
    
14. зайдите через через psql и проверьте содержимое ранее созданной таблицы
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
15. задание со звездочкой *: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.
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

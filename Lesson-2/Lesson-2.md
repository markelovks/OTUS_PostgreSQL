# SQL и реляционные СУБД. Введение в PostgreSQL. 
## Домашнее задание.
1. создать новый проект в Google Cloud Platform, Яндекс облако или на любых ВМ, докере \
далее создать инстанс виртуальной машины с дефолтными параметрами
добавить свой ssh ключ в metadata ВМ

    - Содержание файла Dockerfile.  
    ```
    FROM ubuntu:22.04
    RUN apt update && apt install openssh-server sudo -y \
        && useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ubuntu \
        && echo 'ubuntu:ubuntu' | chpasswd \
        && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
        && mkdir /home/ubuntu/.ssh
    COPY ./ed.pub /home/ubuntu/.ssh/ed.pub
    RUN cat /home/ubuntu/.ssh/ed.pub >> /home/ubuntu/.ssh/authorized_keys \
        && chmod -R go= /home/ubuntu/.ssh \
        && chown -R ubuntu /home/ubuntu/.ssh \
        &&  service ssh start
    EXPOSE 22
    CMD ["/usr/sbin/sshd","-D"]
    ```
    - Содержание файла docker-compose.yml
    ```
    version: '3'
    services:
      postgre:
        build:
          context: .
          dockerfile: Dockerfile
    ```
    - Запуск контейнера
    ```
    docker compose up -d
    ```
2. зайти удаленным ssh (первая сессия), не забывайте про ssh-add
    - Заходим в контейнер 
    ```
    ssh -o StrictHostKeyChecking=no ubuntu@$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' otus_postgresql-postgre-1)
    ```
3. поставить PostgreSQL. 15.
   ```
   sudo apt install -y gnupg2 \
     && sudo apt update && sudo apt upgrade -y \
     && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' 
     && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update \
     && sudo apt-get -y install postgresql-15 \
     && sudo service postgresql start
     && sudo service postgresql status
   ```
   Проверить состояние кластера.
   ```
   sudo -u postgres pg_lsclusters
   ```
4. зайти вторым ssh (вторая сессия)
    - Заходим в контейнер 
    ```
    ssh -o StrictHostKeyChecking=no ubuntu@$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' otus_postgresql-postgre-1)
    ```
5. запустить везде psql из под пользователя postgres
   ```
   sudo -u postgres psql
   ```
6. выключить auto commit
   - Выключить autocommit на текущую сессию
   ```
   \set AUTOCOMMIT off
   ```
   - Проверка auto commit
   ```
   \echo :AUTOCOMMIT
   ```
7. в первой сессии новую таблицу и наполнить ее данными.
   ```
   create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
   ```
   ```
   postgres=# SELECT * FROM persons;
    id | first_name | second_name 
   ----+------------+-------------
     1 | ivan       | ivanov
     2 | petr       | petrov
   (2 rows)
   ```
8. посмотреть текущий уровень изоляции: show transaction isolation level
   ```
   show transaction isolation level; commit;
   ```
   ```
   postgres=# show transaction isolation level;
     transaction_isolation 
    -----------------------
     read committed
    (1 row)
   ```
9. начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
в первой сессии добавить новую запись.
   ```
   insert into persons(first_name, second_name) values('sergey', 'sergeev');
   INSERT 0 1
   ```
10. сделать select from persons во второй сессии
    ```
    postgres=# select * FROM persons;
     id | first_name | second_name 
    ----+------------+-------------
      1 | ivan       | ivanov
      2 | petr       | petrov
    (2 rows)
    ```
11. видите ли вы новую запись и если да то почему?
    - Нет, не вижу, так как изменения в первой сессии не были подтверждены (commit)

12. завершить первую транзакцию - commit; \
    сделать select from persons во второй сессии
    ```
    postgres=*# select * FROM persons;
     id | first_name | second_name 
    ----+------------+-------------
      1 | ivan       | ivanov
      2 | petr       | petrov
      3 | sergey     | sergeev
    (3 rows)


13. видите ли вы новую запись и если да то почему? \
завершите транзакцию во второй сессии

    - Вижу, так как изменения в первой сессии были подтверждены (commit)
14. начать новые но уже repeatable read транзации
    ```
    set transaction isolation level repeatable read;
    SET
    insert into persons(first_name, second_name) values('sveta', 'svetova');
    INSERT 0 1
    ```
15. сделать select* from persons во второй сессии* \
видите ли вы новую запись и если да то почему?
    - Нет, не вижу, так как видим снимок данных на момент начала первого оператора в транзакции. Мы не увидим изменений, внесённых и зафиксированных другими транзакциями после начала этой транзакции, даже если другие транзакции будут подтверждены.
16. завершить первую транзакцию - commit; \
сделать select from persons во второй сессии \
видите ли вы новую запись и если да то почему?
    - Нет, не вижу, так как видим снимок данных на момент начала первого оператора в транзакции. Мы не увидим изменений, внесённых и зафиксированных другими транзакциями после начала этой транзакции, даже если другие транзакции будут подтверждены.
  
17. завершить вторую транзакцию \
сделать select * from persons во второй сессии 
    ```
    postgres=*# commit;
    COMMIT
    postgres=# select * FROM persons;
     id | first_name | second_name 
    ----+------------+-------------
      1 | ivan       | ivanov
      2 | petr       | petrov
      3 | sergey     | sergeev
      4 | sveta      | svetova
    (4 rows)
    ```
18. видите ли вы новую запись и если да то почему?
    - Вижу, так как изменения в первой сессии были подтверждены (commit). И во второй сессии мы работает с обновленным снимком данных до момента первого оператора в транзакции.
     

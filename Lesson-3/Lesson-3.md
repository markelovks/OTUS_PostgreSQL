# Установка PostgreSQL. 
## Домашнее задание.
1. создать ВМ с Ubuntu 20.04/22.04 или развернуть докер любым удобным способом

    - С помощью terraform создал инрфраструктуру в облаке Yandex Cloud. \
      Создано: 
      - облако postgre
      - каталог postgre
      - сеть postgre-network
      - подсеть postgre-ru-central1-a
      - VM postgre-1-ru-central1-a (Ubuntu 22.04 LTS) с публичным ip и metadata с ssh ключом
2. поставить на нем Docker Engine
    ```
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install the Docker packages.
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to Docker group
    sudo usermod -aG docker ${USER}
    su - ${USER}
    ```
    - Проверка \
  <br/>
    ```
    docker version
    Client: Docker Engine - Community
     Version:           26.0.1
     API version:       1.45
     Go version:        go1.21.9
     Git commit:        d260a54
     Built:             Thu Apr 11 10:53:21 2024
     OS/Arch:           linux/amd64
     Context:           default
    
    Server: Docker Engine - Community
     Engine:
      Version:          26.0.1
      API version:      1.45 (minimum version 1.24)
      Go version:       go1.21.9
      Git commit:       60b9add
      Built:            Thu Apr 11 10:53:21 2024
      OS/Arch:          linux/amd64
      Experimental:     false
     containerd:
      Version:          1.6.31
      GitCommit:        e377cd56a71523140ca6ae87e30244719194a521
     runc:
      Version:          1.1.12
      GitCommit:        v1.1.12-0-g51d5e94
     docker-init:
      Version:          0.19.0
      GitCommit:        de40ad0
    
    ```
3. сделать каталог /var/lib/postgres
   ```
   sudo mkdir /var/lib/postgres
   ```
4. развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql \
   развернуть контейнер с клиентом postgres
    - Содержание файла docker-compose.yml
    ```
    services:
      postgre-server:
        image: postgres:15.6-bookworm
        shm_size: 128mb
        environment:
          POSTGRES_USER: user1
          POSTGRES_PASSWORD: user1pwd
          POSTGRES_DB: db1
          PGDATA: "/var/lib/postgresql/data/pgdata"  
        volumes:
          - /var/lib/postgres:/var/lib/postgresql/data/pgdata
        networks:
          postgre:
        ports:
          - "5432:5432"    
    
      postgre-client:
        image: postgres:15.6-bookworm
        shm_size: 128mb
        entrypoint: "sleep infinity"
        networks:
          - postgre
    
    networks:
      postgre:
        driver: bridge
    ```
    - Запуск контейнера
    ```
    docker compose up -d
    ```  

5. подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк
   - Заходим в контейнер 
   ```
   ubuntu@fhmepp00m02kf3i51obn:~$ docker compose exec -it postgre-client psql -h postgre-server -U user1 -d db1
   Password for user user1: 
   psql (15.6 (Debian 15.6-1.pgdg120+2))
   Type "help" for help.
   
   db1=# create table persons(id serial, first_name text, second_name text);
   db1=# insert into persons(first_name, second_name) values('ivan', 'ivanov');
   db1=# insert into persons(first_name, second_name) values('petr', 'petrov');

   db1=# SELECT * FROM persons;
    id | first_name | second_name 
   ----+------------+-------------
     1 | ivan       | ivanov
     2 | petr       | petrov
   (2 rows)
   ```
6. подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера
   ```
   user7@klvd-wxx9 terraform\: psql -h 51.250.73.225 -U user1 -d db1
   Password for user user1: 
   psql (14.11 (Ubuntu 14.11-0ubuntu0.22.04.1), server 15.6 (Debian 15.6-1.pgdg120+2))
   WARNING: psql major version 14, server major version 15.
            Some psql features might not work.
   Type "help" for help.
   
   db1=# 
   db1=# SELECT * FROM persons;
    id | first_name | second_name 
   ----+------------+-------------
     1 | ivan       | ivanov
     2 | petr       | petrov
   (2 rows)
   \q

7. удалить контейнер с сервером
    
<pre><font color="#4E9A06"><b>ubuntu@fhmepp00m02kf3i51obn</b></font>:<font       color="#829395"><b>~</b></font>$ docker compose down
<font color="#3465A4">[+] Running 3/3</font>      
 <font color="#849900">✔</font> Container ubuntu-postgre-client-1  <font       color="#849900">Removed</font>                                                                                                                                                          <font color="#3465A4">10.3s </font>
 <font color="#849900">✔</font> Container ubuntu-postgre-server-1  <font       color="#849900">Removed</font>                                                                                                                                                           <font color="#3465A4">0.3s </font>
 <font color="#849900">✔</font> Network ubuntu_postgre             <font       color="#849900">Removed</font></pre> 
 
8. создать его заново

<pre><font color="#4E9A06"><b>ubuntu@fhmepp00m02kf3i51obn</b></font>:<font color="#829395"><b>~</b></font>$ docker compose up -d
<font color="#3465A4">[+] Running 3/3</font>
 <font color="#849900">✔</font> Network ubuntu_postgre             <font color="#849900">Created</font>                                                                                                                                                           <font color="#3465A4">0.1s </font>
 <font color="#849900">✔</font> Container ubuntu-postgre-server-1  <font color="#849900">Started</font>                                                                                                                                                           <font color="#3465A4">0.1s </font>
 <font color="#849900">✔</font> Container ubuntu-postgre-client-1  <font color="#849900">Started</font></pre>   


9. подключится снова из контейнера с клиентом к контейнеру с сервером
   ```
   ubuntu@fhmepp00m02kf3i51obn:~$ docker compose exec -it postgre-client psql -h postgre-server -U user1 -d db1
   Password for user user1: 
   psql (15.6 (Debian 15.6-1.pgdg120+2))
   Type "help" for help.
   
   db1=#

10. проверить, что данные остались на месте
    ```
    db1=# SELECT * FROM persons;
     id | first_name | second_name 
    ----+------------+-------------
      1 | ivan       | ivanov
      2 | petr       | petrov
    (2 rows)
    
    db1=#       
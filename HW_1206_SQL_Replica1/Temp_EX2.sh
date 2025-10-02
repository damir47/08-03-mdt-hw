# запустили контейнеры
docker run -d --name mysql_master -e MYSQL_ROOT_PASSWORD=rootpassword -d mysql:8.4
docker run -d --name mysql_replica -e MYSQL_ROOT_PASSWORD=rootpassword -d mysql:8.4

# Скопировали к себе и настроили cnf файлы для master и slave
docker cp mysql_master:/etc/my.cnf my-master/my-master.cnf
    log_bin
    server_id=1
docker cp mysql_replica:/etc/my.cnf my-replica/my-replica.cnf
    server_id=2
    read_only=1
# Скопировали cnf файлы на master и slave
docker cp my-master/my-master.cnf mysql_master:/etc/my.cnf
docker cp my-replica/my-replica.cnf mysql_replica:/etc/my.cnf

#Создаем сеть

root@vm-nix-ubnt21:/home/user/mysql-lab# docker network create mysql_replication
7fe127aca55ef1ac61efcdf3f9c620fc630415d898f17c4a747b3adc516f7999
root@vm-nix-ubnt21:/home/user/mysql-lab# docker network connect mysql_replication mysql_master
root@vm-nix-ubnt21:/home/user/mysql-lab# docker network connect mysql_replication mysql_replica


# настроили master
docker exec -it mysql_master mysql -uroot -prootpassword
    # mysql> CREATE USER 'replica'@'%' IDENTIFIED BY 'password';
    mysql> CREATE USER 'replica'@'%';
    Query OK, 0 rows affected (0.05 sec)
    mysql> GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
    Query OK, 0 rows affected (0.01 sec)
    mysql> FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.01 sec)
    mysql> SHOW BINARY LOG STATUS;
    +---------------+----------+--------------+------------------+-------------------+
    | File          | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
    +---------------+----------+--------------+------------------+-------------------+
    | binlog.000002 |      863 |              |                  |                   |
    +---------------+----------+--------------+------------------+-------------------+
    1 row in set (0.00 sec)

    mysql> SHOW DATABASES;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    | performance_schema |
    | sys                |
    +--------------------+
    4 rows in set (0.01 sec)


# Настроили replica
docker exec -it mysql_replica mysql -uroot -prootpassword
    #mysql> CHANGE REPLICATION SOURCE TO SOURCE_HOST='mysql_master',SOURCE_USER='replica',SOURCE_PASSWORD='password',RELAY_LOG_POS=863;
    mysql> CHANGE REPLICATION SOURCE TO SOURCE_HOST='mysql_master',SOURCE_USER='replica',RELAY_LOG_POS=723;
    Query OK, 0 rows affected, 2 warnings (0.02 sec)
    mysql> START REPLICA;
    Query OK, 0 rows affected (0.08 sec)

# перезапустили контейнеры (надо было сделать после правки конфига mysql до старта реплики)
root@vm-nix-ubnt21:/home/user/mysql-lab# docker restart mysql_master
mysql_master
root@vm-nix-ubnt21:/home/user/mysql-lab# docker restart mysql_replica
mysql_replica

# Смотрим статус реплики
mysql> root@vm-nix-ubnt21:/home/user/mysql-lab# docker exec -it mysql_replica mysql -uroot -prootpassword
    mysql: [Warning] Using a password on the command line interface can be insecure.
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 14
    Server version: 8.4.6 MySQL Community Server - GPL

    Copyright (c) 2000, 2025, Oracle and/or its affiliates.

    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW REPLICA STATUS\G;
    ************************** 1. row ***************************
                Replica_IO_State: Waiting for source to send event
                    Source_Host: mysql_master
                    Source_User: replica
                    Source_Port: 3306
                    Connect_Retry: 60
                Source_Log_File: 74dca74a297c-bin.000001
            Read_Source_Log_Pos: 158
                Relay_Log_File: 5e61f2c37df5-relay-bin.000004
                    Relay_Log_Pos: 389
            Relay_Source_Log_File: 74dca74a297c-bin.000001
            Replica_IO_Running: Yes
            Replica_SQL_Running: Yes
                Replicate_Do_DB: 
            Replicate_Ignore_DB: 
            Replicate_Do_Table: 
        Replicate_Ignore_Table: 
        Replicate_Wild_Do_Table: 
    Replicate_Wild_Ignore_Table: 
                    Last_Errno: 0
                    Last_Error: 
                    Skip_Counter: 0
            Exec_Source_Log_Pos: 158
                Relay_Log_Space: 788
                Until_Condition: None
                Until_Log_File: 
                    Until_Log_Pos: 0
            Source_SSL_Allowed: No
            Source_SSL_CA_File: 
            Source_SSL_CA_Path: 
                Source_SSL_Cert: 
                Source_SSL_Cipher: 
                Source_SSL_Key: 
            Seconds_Behind_Source: 0
    Source_SSL_Verify_Server_Cert: No
                    Last_IO_Errno: 0
                    Last_IO_Error: 
                Last_SQL_Errno: 0
                Last_SQL_Error: 
    Replicate_Ignore_Server_Ids: 
                Source_Server_Id: 1
                    Source_UUID: 60607324-9f88-11f0-8c6c-0242ac110002
                Source_Info_File: mysql.slave_master_info
                        SQL_Delay: 0
            SQL_Remaining_Delay: NULL
        Replica_SQL_Running_State: Replica has read all relay log; waiting for more updates
            Source_Retry_Count: 10
                    Source_Bind: 
        Last_IO_Error_Timestamp: 
        Last_SQL_Error_Timestamp: 
                Source_SSL_Crl: 
            Source_SSL_Crlpath: 
            Retrieved_Gtid_Set: 
                Executed_Gtid_Set: 
                    Auto_Position: 0
            Replicate_Rewrite_DB: 
                    Channel_Name: 
            Source_TLS_Version: 
        Source_public_key_path: 
            Get_Source_public_key: 0
                Network_Namespace: 
    1 row in set (0.00 sec)

    ERROR: 
    No query specified

# Проверка что работает:
# На MASTER
mysql> CREATE DATABASE mdt_demo;
Query OK, 1 row affected (0.01 sec)

mysql> USE mdt_demo;
Database changed

mysql> CREATE TABLE books(id INT, name VARCHAR(255));
Query OK, 0 rows affected (0.03 sec)

mysql> INSERT INTO books VALUE(1, 'My book');
Query OK, 1 row affected (0.02 sec)

mysql> SHOW BINARY LOG STATUS\G;
*************************** 1. row ***************************
             File: 74dca74a297c-bin.000002
         Position: 5724
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 
1 row in set (0.00 sec)

ERROR: 
No query specified


(еще вариант)
mysql> CREATE TABLE books(id INT NOT NULL AUTO_INCREMENT, name VARCHAR(255), PRIMARY KEY(id));

# На REPLICA
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mdt_demo           |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.01 sec)

mysql> use mdt_demo;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+--------------------+
| Tables_in_mdt_demo |
+--------------------+
| books              |
+--------------------+
1 row in set (0.00 sec)

mysql> SELECT * FROM books;
+------+---------+
| id   | name    |
+------+---------+
|    1 | My book |
+------+---------+
1 row in set (0.00 sec)


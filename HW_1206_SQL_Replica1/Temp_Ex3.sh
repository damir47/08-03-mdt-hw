user@vm-nix-ubnt21:~/mysql-lab$ tree -L 2
.
├── my-master
│   └── my-master.cnf
├── my-master-dr
│   └── my-master-dr.cnf
└── my-replica
    └── my-replica.cnf

3 directories, 3 files

# Запустили 3й контейнер
docker run -d --name mysql_master_dr -e MYSQL_ROOT_PASSWORD=rootpassword -d mysql:8.4
docker network connect mysql_replication mysql_master_dr

# Настраиваем master и master-dr
docker cp mysql_master:/etc/my.cnf my-master/my-master.cnf
    log_bin
    server_id=1

docker cp mysql_master:/etc/my.cnf my-master-dr/my-master-dr.cnf
    log_bin
    server_id=3

docker cp my-master/my-master.cnf mysql_master:/etc/my.cnf
docker cp my-master-dr/my-master-dr.cnf mysql_master_dr:/etc/my.cnf

# Настройка пользователей
# master
docker exec -it mysql_master mysql -uroot -prootpassword
CREATE USER 'mdt_replica_1'@'%'IDENTIFIED BY 'pass';
GRANT REPLICATION SLAVE ON *.* TO'mdt_replica_1'@'%';
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='mysql_master_dr',
SOURCE_USER='mdt_replica_2',
SOURCE_PASSWORD='pass',
SOURCE_SSL=1;
START REPLICA;

# master_dr
docker exec -it mysql_master_dr mysql -uroot -prootpassword
CREATE USER 'mdt_replica_2'@'%'IDENTIFIED BY 'pass';
GRANT REPLICATION SLAVE ON *.* TO'mdt_replica_2'@'%';
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='mysql_master',
SOURCE_USER='mdt_replica_1',
SOURCE_PASSWORD='pass',
SOURCE_SSL=1;
START REPLICA;
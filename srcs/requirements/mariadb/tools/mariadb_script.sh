#!/bin/bash

service mariadb start

sleep 5

mariadb -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

mariadb -e "CREATE USER '$DB_USER'@'%'IDENTIFIED BY '$DB_USER_PASS';"

mariadb -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';"

mariadb -e "FLUSH PRIVILEGES;"

mariadb-admin -u root shutdown

mariadbd-safe --bind-address=0.0.0.0

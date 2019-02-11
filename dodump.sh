#!/bin/bash
set -e

if [ -n "${MYSQL_USER}" ]; then
    backupdir="$BACKUP_SOURCE/db-mysql"
    if [ -d "$backupdir" ]; then
        echo "Mysql backup failed because directory already exist : $backupdir"
        exit 1
    fi
    if [ -z "${MYSQL_PORT}" ]; then
        MYSQL_PORT=3306
    fi
    if [ -z "${MYSQL_HOST}" ]; then
        MYSQL_HOST=localhost
    fi
    mkdir "$backupdir"
    databases=`mysql -h "${MYSQL_HOST}" -P $MYSQL_PORT --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;""`
    for db in $databases; do
        mysqldump --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db > "$backupdir/$db.sql"
    done
fi
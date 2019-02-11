#!/bin/bash
set -ex

if [ -n "${MYSQL_USERNAME}" ]; then
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
    MYSQL_IGNORE="Database|information_schema|performance_schema"
    mkdir "$backupdir"
    databases=`mysql -h ${MYSQL_HOST} -P $MYSQL_PORT --user=$MYSQL_USERNAME -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "($MYSQL_IGNORE)"`
    for db in $databases; do
        echo -n "[`date`] Dumping database : $db... "
        mysqldump --force --opt -h ${MYSQL_HOST} --user=$MYSQL_USERNAME -p$MYSQL_PASSWORD --databases $db > "$backupdir/$db.sql"
        echo "Done"
    done
fi
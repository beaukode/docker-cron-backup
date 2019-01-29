#!/bin/bash

if [ -z "${BACKUP_CRON}" ]; then
    echo "ERROR: You need at least specify a value for BACKUP_CRON"
    exit 1
fi

if [ -z "${BACKUP_SOURCE}" ]; then
    BACKUP_SOURCE=/backups
fi
export BACKUP_SOURCE=${BACKUP_SOURCE%/}

echo "
export BACKUP_SOURCE=$BACKUP_SOURCE
export FTP_HOST=$FTP_HOST
export FTP_PORT=$FTP_PORT
export FTP_PATH=$FTP_PATH
export FTP_USERNAME=$FTP_USERNAME
export FTP_PASSWORD=$FTP_PASSWORD
" > /env.sh

echo "${BACKUP_CRON} /dobackup.sh" > /crontab.conf
crontab /crontab.conf

exec crond -f

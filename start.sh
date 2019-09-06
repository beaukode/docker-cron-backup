#!/bin/bash

if [ -z "${BACKUP_SOURCE}" ]; then
    BACKUP_SOURCE=/backups
fi
export BACKUP_SOURCE=${BACKUP_SOURCE%/}

./exportenv.sh

if [ -z "${BACKUP_CRON}" ]; then
    /dobackup.sh
else
    echo "${BACKUP_CRON} /dobackup.sh" > /crontab.conf
    crontab /crontab.conf
    exec crond -f
fi


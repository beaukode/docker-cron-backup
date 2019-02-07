#!/bin/bash

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
export SFTP_HOST=$FTP_HOST
export SFTP_PORT=$FTP_PORT
export SFTP_PATH=$FTP_PATH
export SFTP_USERNAME=$FTP_USERNAME
export SFTP_PASSWORD=$FTP_PASSWORD
export SFTP_PRIVKEY=$SFTP_PRIVKEY
export OS_AUTH_URL=$OS_AUTH_URL
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$OS_PASSWORD
export OS_PROJECT_NAME=$OS_PROJECT_NAME
export OS_CONTAINER=$OS_CONTAINER
export OS_PATH=$OS_PATH
" > /env.sh

if [ -z "${BACKUP_CRON}" ]; then
    /dobackup.sh
else
    echo "${BACKUP_CRON} /dobackup.sh" > /crontab.conf
    crontab /crontab.conf
    exec crond -f
fi


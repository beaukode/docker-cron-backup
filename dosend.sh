#!/bin/bash

dosend_ftp ()
{
    if [ -z "${FTP_USERNAME}" ]; then
        >&2 echo "FTP: Unable to send backups FTP_USERNAME value is missing"
        return 1
    fi
    if [ -z "${FTP_PASSWORD}" ]; then
        >&2 echo "FTP: Unable to send backups FTP_PASSWORD value is missing"
        return 1
    fi
    ncftpput -m -u "${FTP_USERNAME}" -p "${FTP_PASSWORD}" -P ${FTP_PORT} "${FTP_HOST}" "${FTP_PATH}/${BACKUP_PREFIX}" ${BACKUP_TMP}/*.tar.gz
}

if [ ! -z "${FTP_HOST}" ]; then
    if [ -z "${FTP_PORT}" ]; then
        FTP_PORT=21
    fi
    if [ -z "${FTP_PATH}" ]; then
        FTP_PATH=/
    else
        FTP_PATH=${FTP_PATH%/}
    fi
    dosend_ftp
fi
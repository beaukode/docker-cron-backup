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
    CMD="ncftpput -m -u ${FTP_USERNAME} -p ${FTP_PASSWORD} -P ${FTP_PORT} ${FTP_HOST} ${FTP_PATH}/${BACKUP_PREFIX} ${BACKUP_TMP}/*.tar.gz"
    $CMD
}

dosend_sftp ()
{
    SFTP_SCRIPT="${BACKUP_TMP}.script"
    if [ -z "${SFTP_USERNAME}" ]; then
        >&2 echo "SFTP: Unable to send backups SFTP_USERNAME value is missing"
        return 1
    fi
    if [ -z "${SFTP_PASSWORD}" ] && [ -z "${SFTP_PRIVKEY}" ]; then
        >&2 echo "SFTP: Unable to send backups, you must set SFTP_PASSWORD or SFTP_PRIVKEY"
        return 1
    fi

    IFS="/"
    read -ra ADDR <<< "$SFTP_PATH"
    IFS=$' \t\n'
    for i in "${ADDR[@]}"; do
        echo "-mkdir ${i}" >> "${SFTP_SCRIPT}"
        echo "cd ${i}" >> "${SFTP_SCRIPT}"
    done
    echo "-mkdir ${BACKUP_PREFIX}" >> "${SFTP_SCRIPT}"
    echo "cd ${BACKUP_PREFIX}" >> "${SFTP_SCRIPT}"

    for D in $BACKUP_TMP/*; do
        echo "put ${D}" >> "${SFTP_SCRIPT}"
    done

    CMD="sftp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o Port=${SFTP_PORT}"
    if [ -z "${SFTP_PRIVKEY}" ]; then
        CMD="sshpass -p ${SFTP_PASSWORD} $CMD"
    else
        CMD="$CMD -i ${SFTP_PRIVKEY}"
    fi
    CMD="$CMD ${SFTP_USERNAME}@${SFTP_HOST}"
    $CMD < ${SFTP_SCRIPT}
    rm "${SFTP_SCRIPT}"
}

dosend_swift () {
    if [ -z "${OS_USERNAME}" ] || [ -z "${OS_PASSWORD}" ] || [ -z "${OS_PROJECT_NAME}" ]; then
        >&2 echo "OS: Unable to send backups, you must set OS_USERNAME, OS_PASSWORD and OS_PROJECT_NAME"
        return 1
    fi
    for D in $BACKUP_TMP/*; do
        BASENAME=`basename $D`
        OBJNAME="${BACKUP_PREFIX}/$BASENAME"
        if [ ! -z "${OS_PATH}" ]; then
            OBJNAME="$OS_PATH/$OBJNAME"
        fi
        swift -A "$OS_AUTH_URL" --os-username "$OS_USERNAME" --os-password "$OS_PASSWORD" \
            --os-project-name "$OS_PROJECT_NAME" upload --object-name "$OBJNAME" "$OS_CONTAINER" $D
    done
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

if [ ! -z "${SFTP_HOST}" ]; then
    if [ -z "${SFTP_PORT}" ]; then
        SFTP_PORT=22
    fi
    if [ -z "${SFTP_PATH}" ]; then
        SFTP_PATH="."
    else
        SFTP_PATH=${SFTP_PATH%/}
    fi
    dosend_sftp
fi

if [ ! -z "${OS_AUTH_URL}" ]; then
    if [ -z "${OS_CONTAINER}" ]; then
        OS_CONTAINER=backups
    fi
    if [ -z "${OS_PATH}" ]; then
        OS_PATH=""
    else
        OS_PATH=${OS_PATH%/}
    fi
    dosend_swift
fi
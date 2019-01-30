#!/bin/bash

assertFileExists ()
{
    if [ -f "$1" ]; then
        echo "PASS: Existing file $1"
    else
        echo "FAIL: Missing file $1"
        exit 1;
    fi
}

assertNotFileExists ()
{
    if [ -f "$1" ]; then
        echo "FAIL: Missing file $1"
        exit 1;
    else
        echo "PASS: Existing file $1"
    fi
}

# Create some stuff to backup
echo "Preparing test files... "
mkdir /backups/dir1
mkdir /backups/dir2
dd if=/dev/urandom of=/backups/dir1/file1a bs=1M count=1
dd if=/dev/urandom of=/backups/dir1/file1b bs=1M count=2
dd if=/dev/urandom of=/backups/dir2/file2a bs=1M count=1
dd if=/dev/urandom of=/backups/dir2/file2b bs=1M count=2

# Prepare backup env
export BACKUP_SOURCE=/backups
export BACKUP_PREFIX=testbackup
export BACKUP_TMP="/tmp/$BACKUP_PREFIX"
rm -Rf /tests-data/ftp/*
rm -Rf $BACKUP_TMP
mkdir $BACKUP_TMP

# Create archives
echo ">Create archives"
assertNotFileExists "${BACKUP_TMP}/dir1.tar.gz"
assertNotFileExists "${BACKUP_TMP}/dir2.tar.gz"
/docompress.sh
assertFileExists "${BACKUP_TMP}/dir1.tar.gz"
assertFileExists "${BACKUP_TMP}/dir2.tar.gz"

# Do nothing
echo ">Do nothing"
/dosend.sh

# Send to FTP
echo ">Send to FTP"
export FTP_HOST=ftp
export FTP_PORT=29999
export FTP_USERNAME=testuser
export FTP_PASSWORD=testpasswd
assertNotFileExists "/tests-data/ftp/testbackup/dir1.tar.gz"
assertNotFileExists "/tests-data/ftp/testbackup/dir2.tar.gz"
/dosend.sh
assertFileExists "/tests-data/ftp/testbackup/dir1.tar.gz"
assertFileExists "/tests-data/ftp/testbackup/dir2.tar.gz"
unset FTP_HOST FTP_PORT FTP_PATH FTP_USERNAME FTP_PASSWORD
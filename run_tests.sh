#!/bin/bash
set -e

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
        echo "FAIL: Existing file $1"
        exit 1;
    else
        echo "PASS: Not existing file $1"
    fi
}

assertFtpFileExists ()
{
    ret=0
    ncftpget -c -u ${FTP_USERNAME} -p ${FTP_PASSWORD} -P ${FTP_PORT} ${FTP_HOST} $1 > /dev/null || ret=$?
    if [ $ret -eq 0 ]; then
        echo "PASS: Existing ftp file $1"
    else
        echo "FAIL: Missing ftp file $1"
        exit 1;
    fi
}

assertFtpNotFileExists ()
{
    ret=0
    ncftpget -c -u ${FTP_USERNAME} -p ${FTP_PASSWORD} -P ${FTP_PORT} ${FTP_HOST} $1 > /dev/null || ret=$?
    if [ $ret -eq 0 ]; then
        echo "FAIL: Existing ftp file $1"
        exit 1;
    else
        echo "PASS: Not existing ftp file $1"
    fi
}

assertSftpFileExists ()
{
    ret=0
    sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /id_rsa ${SFTP_USERNAME}@${SFTP_HOST}:$1 || ret=$?
    if [ $ret -eq 0 ]; then
        echo "PASS: Existing sftp file $1"
    else
        echo "FAIL: Missing sftp file $1"
        exit 1;
    fi
}

assertSftpNotFileExists ()
{
    ret=0
    sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /id_rsa ${SFTP_USERNAME}@${SFTP_HOST}:$1 || ret=$?
    if [ $ret -eq 0 ]; then
        echo "FAIL: Existing sftp file $1"
        exit 1;
    else
        echo "PASS: Not existing sftp file $1"
    fi
}

assertSwiftFileExists ()
{
    if [ $? -eq 0 ]; then
        echo "PASS: Existing swift file $1"
    else
        echo "FAIL: Missing swift file $1"
        exit 1;
    fi
}

assertSwiftNotFileExists ()
{
    swift -A http://swift:5000/v2.0/ --os-username admin --os-password s3cr3t --os-project-name admin stat test_backups $1
    if [ $? -eq 0 ]; then
        echo "FAIL: Existing swift file $1"
        exit 1;
    else
        echo "PASS: Not existing swift file $1"
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
rm -Rf $BACKUP_TMP
mkdir $BACKUP_TMP

# Wait services
dockerize -wait tcp://ftp:29999 -wait tcp://sftp:22 -wait tcp://swift:5001 -timeout 60s

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
export FTP_PATH=data
export FTP_USERNAME=testuser
export FTP_PASSWORD=testpasswd
assertFtpNotFileExists "data/testbackup/dir1.tar.gz"
assertFtpNotFileExists "data/testbackup/dir2.tar.gz"
/dosend.sh
assertFtpFileExists "data/testbackup/dir1.tar.gz"
assertFtpFileExists "data/testbackup/dir2.tar.gz"
unset FTP_HOST FTP_PORT FTP_PATH FTP_USERNAME FTP_PASSWORD

# Send to SFTP (password)
echo ">Send to SFTP (password)"
export SFTP_HOST=sftp
export SFTP_USERNAME=sftpuser
export SFTP_PASSWORD=testpasswd
export SFTP_PATH=incoming
assertSftpNotFileExists "incoming/testbackup/dir1.tar.gz"
assertSftpNotFileExists "incoming/testbackup/dir2.tar.gz"
/dosend.sh
assertSftpFileExists "incoming/testbackup/dir1.tar.gz"
assertSftpFileExists "incoming/testbackup/dir2.tar.gz"
sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /id_rsa $SFTP_USERNAME@$SFTP_HOST <<EOF
rm incoming/testbackup/*
rmdir incoming/testbackup
exit
EOF
unset SFTP_HOST SFTP_PORT SFTP_PATH SFTP_USERNAME SFTP_PASSWORD

# Send to SFTP (key)
echo ">Send to SFTP (key)"
export SFTP_HOST=sftp
export SFTP_USERNAME=sftpuser
export SFTP_PRIVKEY=/id_rsa
export SFTP_PATH=incoming
assertSftpNotFileExists "incoming/testbackup/dir1.tar.gz"
assertSftpNotFileExists "incoming/testbackup/dir2.tar.gz"
/dosend.sh
assertSftpFileExists "incoming/testbackup/dir1.tar.gz"
assertSftpFileExists "incoming/testbackup/dir2.tar.gz"
sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /id_rsa $SFTP_USERNAME@$SFTP_HOST <<EOF
rm incoming/testbackup/*
rmdir incoming/testbackup
exit
EOF
unset SFTP_HOST SFTP_PORT SFTP_PATH SFTP_USERNAME SFTP_PASSWORD

# Send to OpenStack Swift
echo ">Send to OpenStack Swift"
export OS_AUTH_URL=http://swift:5000/v2.0/
export OS_USERNAME=admin
export OS_PASSWORD=s3cr3t
export OS_PROJECT_NAME=admin
export OS_CONTAINER=test_backups
assertSwiftNotFileExists "testbackup/dir1.tar.gz"
assertSwiftNotFileExists "testbackup/dir2.tar.gz"
/dosend.sh
assertSwiftFileExists "testbackup/dir1.tar.gz"
assertSwiftFileExists "testbackup/dir2.tar.gz"
swift -A http://swift:5000/v2.0/ --os-username admin --os-password s3cr3t --os-project-name admin delete $OS_CONTAINER # delete container
unset OS_AUTH_URL OS_USERNAME OS_PASSWORD OS_PROJECT_NAME OS_CONTAINER
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

assertFileEqual ()
{
    ret=0
    diff "$1" "$2" > /dev/null || ret=$?
    if [ $ret -eq 0 ]; then
        echo "PASS: Files $1 $2 are equals"
    else
        diff "$1" "$2"
        echo "FAIL: Files $1 $2 are not equals"
        exit 1;
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
    ret=0
    swift -A http://swift:5000/v2.0/ --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-project-name $OS_PROJECT_NAME --os-region-name "$OS_REGION_NAME" stat test_backups $1 || ret=$?
    if [ $ret -eq 0 ]; then
        echo "PASS: Existing swift file $1"
    else
        echo "FAIL: Missing swift file $1"
        exit 1;
    fi
}

assertSwiftNotFileExists ()
{
    ret=0
    swift -A http://swift:5000/v2.0/ --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-project-name $OS_PROJECT_NAME --os-region-name "$OS_REGION_NAME" stat test_backups $1 || ret=$?
    if [ $ret -eq 0 ]; then
        echo "FAIL: Existing swift file $1"
        exit 1;
    else
        echo "PASS: Not existing swift file $1"
    fi
}

# Export env vars for backup script
echo ">Export env vars for backup script"
export BACKUP_SOURCE=A
export MYSQL_HOST=B
export MYSQL_PORT=C
export MYSQL_USERNAME=D
export MYSQL_PASSWORD=E
export FTP_HOST=F
export FTP_PORT=G
export FTP_PATH=H
export FTP_USERNAME=I
export FTP_PASSWORD=J
export SFTP_HOST=K
export SFTP_PORT=L
export SFTP_PATH=M
export SFTP_USERNAME=N
export SFTP_PASSWORD=O
export SFTP_PRIVKEY=P
export OS_AUTH_URL=Q
export OS_USERNAME=R
export OS_PASSWORD=S
export OS_PROJECT_NAME=T
export OS_REGION_NAME=U
export OS_DELETE_AFTER=V
export OS_CONTAINER=W
export OS_PATH=X
./exportenv.sh
assertFileEqual "env.sh" "env.sh.snapshot"
unset BACKUP_SOURCE
unset MYSQL_HOST MYSQL_PORT MYSQL_USERNAME MYSQL_PASSWORD
unset FTP_HOST FTP_PORT FTP_USERNAME FTP_PATH FTP_PASSWORD
unset SFTP_HOST SFTP_PORT SFTP_PATH SFTP_USERNAME SFTP_PASSWORD SFTP_PRIVKEY
unset OS_AUTH_URL OS_USERNAME OS_PASSWORD OS_PROJECT_NAME OS_REGION_NAME OS_DELETE_AFTER OS_CONTAINER OS_PATH

# Create some stuff to backup
echo "Preparing test files... "
mkdir /backups/dir1
mkdir /backups/dir2
dd if=/dev/urandom of=/backups/dir1/file1a bs=1M count=1
dd if=/dev/urandom of=/backups/dir1/file1b bs=1M count=2
dd if=/dev/urandom of=/backups/dir2/file2a bs=1M count=1
dd if=/dev/urandom of=/backups/dir2/file2b bs=1M count=2
echo "Preparing databases... "
mysql -h mysql -u testuser -ps3cr3t testdb < /randomdata.sql

# Prepare backup env
export BACKUP_SOURCE=/backups
export BACKUP_PREFIX=testbackup
export BACKUP_TMP="/tmp/$BACKUP_PREFIX"
rm -Rf $BACKUP_TMP
mkdir $BACKUP_TMP

# Dump databases
echo ">Dump MySQL databases"
export MYSQL_HOST=mysql
export MYSQL_USERNAME=root
export MYSQL_PASSWORD=s3cr3t
assertNotFileExists "${BACKUP_SOURCE}/db-mysql/testdb.sql"
/dodump.sh
assertFileExists "${BACKUP_SOURCE}/db-mysql/testdb.sql"

# Create archives
echo ">Create archives"
assertNotFileExists "${BACKUP_TMP}/dir1.tar.gz"
assertNotFileExists "${BACKUP_TMP}/dir2.tar.gz"
assertNotFileExists "${BACKUP_TMP}/db-mysql.tar.gz"
/docompress.sh
assertFileExists "${BACKUP_TMP}/dir1.tar.gz"
assertFileExists "${BACKUP_TMP}/dir2.tar.gz"
assertFileExists "${BACKUP_TMP}/db-mysql.tar.gz"

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
export OS_REGION_NAME=RegionOne
export OS_CONTAINER=test_backups
assertSwiftNotFileExists "testbackup/dir1.tar.gz"
assertSwiftNotFileExists "testbackup/dir2.tar.gz"
/dosend.sh
assertSwiftFileExists "testbackup/dir1.tar.gz"
assertSwiftFileExists "testbackup/dir2.tar.gz"
swift -A http://swift:5000/v2.0/ --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-project-name $OS_PROJECT_NAME --os-region-name "$OS_REGION_NAME" delete $OS_CONTAINER # delete container
unset OS_AUTH_URL OS_USERNAME OS_PASSWORD OS_REGION_NAME OS_PROJECT_NAME OS_CONTAINER

# Send to OpenStack Swift
echo ">Send to OpenStack Swift (With expiration)"
export OS_AUTH_URL=http://swift:5000/v2.0/
export OS_USERNAME=admin
export OS_PASSWORD=s3cr3t
export OS_PROJECT_NAME=admin
export OS_REGION_NAME=RegionOne
export OS_CONTAINER=test_backups
export OS_DELETE_AFTER=5
assertSwiftNotFileExists "testbackup/dir1.tar.gz"
assertSwiftNotFileExists "testbackup/dir2.tar.gz"
/dosend.sh
assertSwiftFileExists "testbackup/dir1.tar.gz"
assertSwiftFileExists "testbackup/dir2.tar.gz"
echo "Waiting 10s file expiration... "
sleep 10
assertSwiftNotFileExists "testbackup/dir1.tar.gz"
assertSwiftNotFileExists "testbackup/dir2.tar.gz"
swift -A http://swift:5000/v2.0/ --os-username $OS_USERNAME --os-password $OS_PASSWORD --os-project-name $OS_PROJECT_NAME --os-region-name "$OS_REGION_NAME" delete $OS_CONTAINER || true # delete container
unset OS_AUTH_URL OS_USERNAME OS_PASSWORD OS_REGION_NAME OS_DELETE_AFTER OS_PROJECT_NAME OS_CONTAINER
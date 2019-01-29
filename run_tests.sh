#!/bin/bash

# Create some stuff to backup
mkdir /backups/dir1
mkdir /backups/dir2

dd if=/dev/random of=/backups/dir1/file1a bs=1K count=1
dd if=/dev/random of=/backups/dir1/file1b bs=1K count=2
dd if=/dev/random of=/backups/dir2/file2a bs=1K count=1
dd if=/dev/random of=/backups/dir2/file2b bs=1K count=2

export BACKUP_PREFIX=`date +%Y-%m-%d_%H-%M-%S`
export BACKUP_TMP="/tmp/$BACKUP_PREFIX"

/dobackup.sh

env
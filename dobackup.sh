#!/bin/bash
source /env.sh

export BACKUP_PREFIX=`date +%Y-%m-%d_%H-%M-%S`
export BACKUP_TMP="/tmp/$BACKUP_PREFIX"

echo "[`date`] Starting backup"
echo "[`date`] Création temp directory : $BACKUP_TMP"
mkdir $BACKUP_TMP
/docompress.sh
/dosend.sh
rm -Rf $BACKUP_TMP
echo "[`date`] Backup done"
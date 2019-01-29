#!/bin/bash

OLD_PWD=`pwd`
cd $BACKUP_SOURCE
for D in */; do
    echo -n "[`date`] Archiving : ${D%/}... "
    tar czf "$BACKUP_TMP/${D%/}.tar.gz" "${D%/}"
    echo "Done"
done
cd "$OLD_PWD"
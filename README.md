# Docker-cron-backup
This docker image to plan file &amp; mysql backup ftp/sftp

## Usage
Run image and mount everythings you want in /backups !

### Backup every home
Mount /home as /backups then it will create a user.tar.gz for each users
```
docker run -d \
       -v /home:/backups
       --env BACKUP_CRON=0 0 * * * \
       beaukode/cron-backup
```

### Backup random directories
Mount them in /backups and it will create 2 archives : etc.tar.gz & webroot.tar.gz
```
docker run -d \
       -v /etc:/backups/etc
       -v /var/www:/backups/webroot
       --env BACKUP_CRON=0 0 * * * \
       beaukode/cron-backup
```

## General variables
* **BACKUP_CRON** : Cron expression to plan backups
* **BACKUP_SOURCE** (Default: /backups) : Directory to backup. **ONLY** each subdirectory will be saved as tar.gz archives. *Files and dots directories on this root directory is ignored*

## FTP
* **FTP_HOST** : Send archives to this FTP host in a directory named FTP_PATH/DATE_TIME/
* **FTP_PORT** (Default: 21) : FTP server port
* **FTP_PATH** (Default: /) : Path on FTP to put backup in
* **FTP_USERNAME** : FTP account username
* **FTP_PASSWORD** : FTP account password

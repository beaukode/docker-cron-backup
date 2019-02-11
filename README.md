# Docker-cron-backup
This docker image is a simple way to backup files and databases

## Usage
Run image and mount everythings you want in /backups !
You can use cron expression to plan backups or use external runner like crontab, kubernetes cronjobs, etc...

### Backup every home
Mount /home to /backups then it will create a user.tar.gz for each users
```
docker run -d \
       -v /home:/backups
       beaukode/cron-backup
```

### Backup every home and send them to remote sFTP
This exemple use openssh key from ~/.ssh/id_rsa
```
docker run -d \
       -v /home:/backups
       -v `echo $HOME`/.ssh/id_rsa:/id_rsa
       --env SFTP_HOST=127.0.0.1
       --env SFTP_USERNAME=backup
       --env SFTP_PRIVKEY=/id_rsa
       beaukode/cron-backup
```

### Backup random directories
Mount them in /backups and it will create 2 archives (etc.tar.gz & webroot.tar.gz) every day at midnight
```
docker run -d \
       -v /etc:/backups/etc
       -v /var/www:/backups/webroot
       --env BACKUP_CRON=0 0 * * * \
       beaukode/cron-backup
```

## Variables
* **BACKUP_CRON** : Cron expression to plan backups, leave empty to run once then exit
* **BACKUP_SOURCE** (Default: /backups) : Directory to backup. **ONLY** each subdirectory will be saved as tar.gz archives. *Files and dots directories on this root directory is ignored*

## FTP
* **FTP_HOST** : Send archives to this FTP host in a directory named FTP_PATH/DATE_TIME/
* **FTP_PORT** (Default: 21) : FTP server port
* **FTP_PATH** (Default: /) : Path on FTP to put backup in
* **FTP_USERNAME** : FTP account username
* **FTP_PASSWORD** : FTP account password

## SFTP
* **SFTP_HOST** : Send archives to this SFTP host in a directory named SFTP_PATH/DATE_TIME/
* **SFTP_PORT** (Default: 22) : SFTP server port
* **SFTP_PATH** (Default: .) : Path on SFTP to put backup in
* **SFTP_USERNAME** : SFTP account username
* **SFTP_PASSWORD** : SFTP account password
* **SFTP_PRIVKEY** : Unencrypted OpenSSH private key (without passphrase !)

## Openstack Swift
* **OS_AUTH_URL** : Openstack auth URL (Auth version 2)
* **OS_USERNAME** : Openstack account username
* **OS_PASSWORD** : Openstack account password
* **OS_PROJECT_NAME** : Openstack project or tenant name
* **OS_CONTAINER** (Default: backups) : Openstack target container
* **OS_PATH** (Default: /) : Openstack path for backups inside container

# Contributions
You are welcome to contribute code and docs
Please write tests and open pull request to integrate your work
Spellchecking and more examples to this readme would be nice, english is not my primary language

# Issues
Please report issues at GitHub https://github.com/beaukode/docker-cron-backup/issues

# Todo
* Database backups : mysql & mongodb
* Openstack swift target
* Amazon : S3, Glacier
* Google cloud storage

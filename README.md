# mysql-backup azure

This image runs mysqldump to backup data using cronjob to folder `/backup` and azure storage service

## Usage:

    docker run -d \
        --env MYSQL_HOST=mysql.host \
        --env MYSQL_PORT=27017 \
        --env MYSQL_USER=admin \
        --env MYSQL_PASS=password \
        --volume host.folder:/backup
        --env AZ_USER=[Application ID GUID] \
        --env AZ_SECRET=[Application KEY] \
        --env AZ_AD_TENANT_ID=[Tenant AD ID GUID] \
        --env AZ_STORAGE_SHARE=[Share name] \
        --env AZ_STORAGE_FOLDER=[Folder to save] \
        --env AZ_STORAGE_CS=[Storage connection string] \
        dimkk/azure-docker-mysql-backup

Moreover, if you link `dimkk/azure-docker-mysql-backup` to a mysql container(e.g. `tutum/mysql`) with an alias named mysql, this image will try to auto load the `host`, `port`, `user`, `pass` if possible.

    docker run -d -p 27017:27017 -p 28017:28017 -e MYSQL_PASS="mypass" --name mysql tutum/mysql
    docker run -d --link mysql:mysql -v host.folder:/backup tutum/mysql-backup

## Parameters

    MYSQL_HOST      the host/ip of your mysql database
    MYSQL_PORT      the port number of your mysql database
    MYSQL_USER      the username of your mysql database
    MYSQL_PASS      the password of your mysql database
    MYSQL_DB        the database name to dump. Default: `--all-databases`
    EXTRA_OPTS      the extra options to pass to mysqldump command
    CRON_TIME       the interval of cron job to run mysqldump. `0 0 * * *` by default, which is every day at 00:00
    MAX_BACKUPS     the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
    INIT_BACKUP     if set, create a backup when the container starts
    INIT_RESTORE_LATEST if set, restores latest backup
    AZ_USER         azure application guid, to get it, and AZ_SECRET, if set, azure save/delete will work [read here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal)
    AZ_SECRET=      azure application secret
    AZ_AD_TENANT_ID azure Active Directory Tenant ID, you can find it here -> https://manage.windowsazure.com/serco.onmicrosoft.com#Workspaces/ActiveDirectoryExtension/Directory/**<Tenant ID GUID>**/directoryQuickStart
    AZ_STORAGE_FOLDER azure folder in share to save backups
    AZ_STORAGE_SHARE azure share name - create it yourself!
    AZ_STORAGE_CS   azure storage connection string


## Restore from a backup

See the list of backups, you can run:

    docker exec tutum-backup ls /backup

To restore database from a certain backup, simply run:

    docker exec tutum-backup /restore.sh /backup/2015.08.06.171901
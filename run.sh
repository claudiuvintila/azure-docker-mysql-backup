#!/bin/bash

if [ "${MYSQL_ENV_MYSQL_PASS}" == "**Random**" ]; then
        unset MYSQL_ENV_MYSQL_PASS
fi

MYSQL_HOST=${MYSQL_PORT_3306_TCP_ADDR:-${MYSQL_HOST}}
MYSQL_HOST=${MYSQL_PORT_1_3306_TCP_ADDR:-${MYSQL_HOST}}
MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT:-${MYSQL_PORT}}
MYSQL_PORT=${MYSQL_PORT_1_3306_TCP_PORT:-${MYSQL_PORT}}
MYSQL_USER=${MYSQL_USER:-${MYSQL_ENV_MYSQL_USER}}
MYSQL_PASS=${MYSQL_PASS:-${MYSQL_ENV_MYSQL_PASS}}

AZ_USER=${AZ_USER}
AZ_SECRET=${AZ_SECRET}
AZ_AD_TENANT_ID=${AZ_AD_TENANT_ID}
AZ_STORAGE_FOLDER=${AZ_STORAGE_FOLDER}
AZ_STORAGE_SHARE=${AZ_STORAGE_SHARE}
AZ_STORAGE_CS=${AZ_STORAGE_CS}

[ -z "${MYSQL_HOST}" ] && { echo "=> MYSQL_HOST cannot be empty" && exit 1; }
[ -z "${MYSQL_PORT}" ] && { echo "=> MYSQL_PORT cannot be empty" && exit 1; }
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
[ -z "${MYSQL_PASS}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }

BACKUP_CMD="mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASS} ${EXTRA_OPTS} ${MYSQL_DB} > /backup/"'${BACKUP_NAME}'

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash

if [ -n ${AZ_USER} ]; then
    az login --service-principal -u \${AZ_USER} -p "\${AZ_SECRET}" --tenant \${AZ_AD_TENANT_ID}
    az storage directory create -n \${AZ_STORAGE_FOLDER} --share-name \${AZ_STORAGE_SHARE} --connection-string "\${AZ_STORAGE_CS}"
fi

MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H\%M\%S).sql

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    echo "   Backup succeeded"
    if [ -n ${AZ_USER} ]; then
        az storage file upload -s ${AZ_STORAGE_SHARE}/${AZ_STORAGE_FOLDER} --source /backup/\${BACKUP_NAME} --connection-string "\${AZ_STORAGE_CS}"
    fi
else
    echo "   Backup failed"
    rm -rf /backup/\${BACKUP_NAME}
fi

if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup -N1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backup -N1 | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backup/\${BACKUP_TO_BE_DELETED}
        if [ -n ${AZ_USER} ]; then
            az storage file delete -s \${AZ_STORAGE_SHARE} -p \${AZ_STORAGE_FOLDER}/\${BACKUP_TO_BE_DELETED} --connection-string "\${AZ_STORAGE_CS}"
        fi
    done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/bash
echo "=> Restore database from \$1"
if mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASS} < \$1 ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

touch /mysql_backup.log
tail -F /mysql_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore lates backup"
    until nc -z $MYSQL_HOST $MYSQL_PORT
    do
        echo "waiting database container..."
        sleep 1
    done
    ls -d -1 /backup/* | tail -1 | xargs /restore.sh
fi

echo "${CRON_TIME} /backup.sh >> /mysql_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec crond
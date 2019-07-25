#!/usr/bin/env bash

source /env.sh

if [[ -z "${BACKUP_DIRECTORY}" ]]; then
    exit 1;
fi;

function backup_name {
    echo ${backup_location}/$1_${backup_name}
}

backup_name=database.sql.gz
extra_flags=""
backup_location=${BACKUP_DIRECTORY}
backup_count=12

mysqldump -h $WORDPRESS_DB_HOST -u $WORDPRESS_DB_USER --password=$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_NAME -c | gzip -n > "$(backup_name tmp)"

if [[ -f "$(backup_name 0)" ]]; then
    OLD_HASH=`sha256sum -b "$(backup_name 0)" | head -c 64`
    NEW_HASH=`sha256sum -b "$(backup_name tmp)" | head -c 64`

    if [[ "${OLD_HASH}" == "${NEW_HASH}" ]]; then
        rm "$(backup_name tmp)"
        exit 0;
    fi;

fi;

if [[ -f "$(backup_name ${backup_count})" ]]; then
    rm "$(backup_name ${backup_count})"
fi;

for I in `seq ${backup_count} -1 1`; do
    let J=I-1
    if [[ -f "$(backup_name $J)" ]]; then
        mv "$(backup_name $J)" "$(backup_name $I)"
    fi;
done

mv "$(backup_name tmp)" "$(backup_name 0)"

exit 0;

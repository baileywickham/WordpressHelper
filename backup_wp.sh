#!/usr/bin/env bash

if [ -f utils.sh ]; then
    source utils.sh
else
    curl https://raw.githubusercontent.com/baileywickham/personal_packages/master/utils.sh > utils.sh
fi

source vars.sh

time=$(date +%Y-%m-%d_%H-%M-%S)

function backup_db() {
    task "Back up db"
    db_name="${wp_site_name}_${time}.sql.gz"

    with_sudo mysqldump -u wordpress -p wordpress | gzip > $db_name
    with_sudo mv $db_name ${wp_directory}/${db_name}
}

function backup_wp() {
    task "Back up wp"
    tar -zcvf ${wp_site_name}_${time}.tar.gz $wp_directory
}

function backup_site() {
    backup_db && backup_site
}

if [[ $1 == "--backup" ]]; then
    backup_site
else
    echo "use --backup to backup"
    echo -n
    exit 1
fi

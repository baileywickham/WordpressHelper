#!/usr/bin/env bash

if [ -f utils.sh ]; then
    source utils.sh
else
    curl https://raw.githubusercontent.com/baileywickham/personal_packages/master/utils.sh > utils.sh
fi

source vars.sh

set -uo pipefail

time=$(date +%Y-%m-%d_%H-%M-%S)

function backup_db() {
    task "Back up db"
    db_name="${wp_site_name}_${time}.sql.gz"

    mysqldump -u root wordpress | gzip > $db_name
    with_sudo mv $db_name ${wp_directory}/${db_name}
}

function backup_wp() {
    task "Back up wp"
    tar -zcvf ${wp_site_name}_${time}.tar.gz $wp_directory
}

function backup_site() {
    backup_db
    backup_wp
}

if [[ $# -eq 1 && $1 == "--backup" ]]; then
    backup_site
else
    echo "use --backup to backup"
    echo -n
fi

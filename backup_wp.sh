#!/usr/bin/env bash

function help() {
    echo "use --backup to backup site"
}
if [[ $# -le 0 ]]; then
    help
fi

if [ -f utils.sh ]; then
    source utils.sh
else
    curl -s https://raw.githubusercontent.com/baileywickham/personal_packages/master/utils.sh > utils.sh
fi

source vars.sh

set -uo pipefail

time=$(date +%Y-%m-%d_%H-%M-%S)

function backup_db() {
    task "Back up db"
    db_name="${wp_site_name}_${time}.sql.gz"

    with_sudo mysqldump -u root wordpress | gzip > $db_name
    with_sudo mv $db_name ${wp_directory}/${db_name}
}

function backup_wp() {
    task "Back up wp"
    tar -zcf ${wp_site_name}_${time}.tar.gz -C $wp_parent_directory $(basename ${wp_directory})
}

function backup_site() {
    backup_db
    backup_wp
}


while [[ $# -gt 0 && ${1} ]]; do
    case "${1}" in
        --backup)
            backup_site
            shift
            ;;
        *)
            help
            shift
            ;;
    esac
done



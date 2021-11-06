#!/usr/bin/env bash
if [ -f utils.sh ]; then
    source utils.sh
else
    curl -s https://raw.githubusercontent.com/baileywickham/personal_packages/master/utils.sh > utils.sh
    source utils.sh
fi

function help() {
    echo "use --install to install"
    echo "use --restore <filename> to restore from a backup. Wipes server"
}

if [[ $# -le 0 ]]; then
    help
fi

#https://api.wordpress.org/secret-key/1.1/salt/
source vars.sh

set -uo pipefail

wp_parent_directory=/var/www/
wp_directory=/var/www/wordpress

wp_url=""
db_password=""

function generate_password () {
    task "Generating pw"
    db_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12} | tr -d \n)
    echo "db_password: $db_password" > $HOME/db_password
}

function install_wp_packages () {
    task "Installing packages"
    apt_update
    apt_install apt-utils \
        apache2 \
        ghostscript \
        libapache2-mod-php \
        mysql-server \
        php \
        php-bcmath \
        php-curl \
        php-imagick \
        php-intl \
        php-json \
        php-mbstring \
        php-mysql \
        php-xml \
        php-zip \
        fail2ban

    echo -n
}

function download_wp () {
    task "Downloading wp"
    with_sudo chown www-data: $wp_parent_directory
    curl -s https://wordpress.org/latest.tar.gz | with_sudo tar zx -C $wp_parent_directory
    with_sudo chown -R www-data $wp_directory
}

function get_servername() {
    if [[ $wp_url == "" ]]; then
        echo ""
    else
        echo "ServerName $wp_url"
    fi
}

function configure_apache() {
    task "Configuring Apache"

    cat << EOF > tmpfile
    <VirtualHost *:80>
    $(get_servername)
    DocumentRoot ${wp_directory}
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory ${wp_directory}/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
    </VirtualHost>
EOF

with_sudo mv tmpfile /etc/apache2/sites-available/wordpress.conf

with_sudo a2ensite wordpress
with_sudo a2dissite 000-default
with_sudo a2enmod rewrite
with_sudo service apache2 restart

}

function create_db () {
    task "Creating DB"
    cat << EOF |
    CREATE DATABASE wordpress;
    CREATE USER wordpress@localhost IDENTIFIED BY '$db_password';
    GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO wordpress@localhost;
    FLUSH PRIVILEGES;
EOF

with_sudo mysql -u root

}

function create_wp_config () {
    task "Creating wp-config"
    cat << EOF |
     # Block WordPress xmlrpc.php requests
    <Files xmlrpc.php>
    order deny,allow
    deny from all
    </Files>
EOF
sudo tee ${wp_directory}/.htaccess > /dev/null

cwd=$(pwd)
cd $wp_directory
with_sudo cp wp-config-sample.php wp-config.php
with_sudo chown www-data wp-config.php
with_sudo sed -i 's/database_name_here/wordpress/' ${wp_directory}/wp-config.php
with_sudo sed -i 's/username_here/wordpress/' ${wp_directory}/wp-config.php
with_sudo sed -i 's/password_here/'${db_password}'/' ${wp_directory}/wp-config.php

curl -s https://api.wordpress.org/secret-key/1.1/salt/ | sudo tee -a ${wp_directory}/wp-config.php > /dev/null
cd $cwd
}


function install_site () {
    task "Main"
    install_wp_packages
    configure_apache

    generate_password
    download_wp && create_wp_config

    create_db
}

function delete_current_db () {
    task "Deleting current db"
    cat << EOF |
    DROP DATABASE IF EXISTS wordpress;
    DROP USER IF EXISTS wordpress@localhost;
EOF

with_sudo mysql -u root
}

function unpack_backup () {
    task "Unpacking backup"
    with_sudo tar -zxf $backup_file -C ${wp_parent_directory} --directory $(basename ${wp_directory})
    with_sudo chown www-data: $wp_parent_directory
}

function restore_db() {
    local filename="$wp_directory/$(basename ${backup_file%.*}).sql.gz"
    unzip < $filename | with_sudo mysql -u root wordpress

}

function restore_site () {
    task "Restoring wp install"
    with_sudo rm -rf ${wp_directory}
    delete_current_db
    install_site
    unpack_backup
}


while [[ $# -gt 0 && ${1} ]]; do
    case "${1}" in
        --install)
            install_site
            break;
            ;;

        --restore)
            if [[ $# -ne 2 ]]; then
                echo "backup requires a backup file"
                exit 1
            fi
            backup_file=${2}
            restore_site
            shift
            break;
            ;;
        *)
            help
            break
            ;;
    esac
done

#!/usr/bin/env bash

if [ -f utils.sh ]; then
    source utils.sh
else
    curl https://raw.githubusercontent.com/baileywickham/personal_packages/master/utils.sh > utils.sh
    source utils.sh
fi
#https://api.wordpress.org/secret-key/1.1/salt/

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
    curl https://wordpress.org/latest.tar.gz | with_sudo tar zx -C $wp_parent_directory
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
    cwd=$(pwd)
    cd $wp_directory
    with_sudo cp wp-config-sample.php wp-config.php
    with_sudo chown www-data wp-config.php
    with_sudo sed -i 's/database_name_here/wordpress/' ${wp_directory}/wp-config.php
    with_sudo sed -i 's/username_here/wordpress/' ${wp_directory}/wp-config.php
    with_sudo sed -i 's/password_here/'${db_password}'/' ${wp_directory}/wp-config.php

    curl https://api.wordpress.org/secret-key/1.1/salt/ | sudo tee -a ${wp_directory}/wp-config.php > /dev/null
    cd $cwd
}

function main () {
    task "Main"
    install_wp_packages
    configure_apache

    generate_password
    download_wp && create_wp_config

    create_db
}

if [[ $1 == "--install" ]]; then
    main
else
    echo "use --install to install"
    echo -n
fi


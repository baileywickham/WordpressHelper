#!/usr/bin/env bash

source utils.sh

wp_directory=/var/www/
wp_url=""

function generate_password () {
    < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12}
}

function install_wp_packages () {
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
        php-zip

    echo -n
}

function download () {
    with_sudo chown www-data: $wp_directory
    curl https://wordpress.org/latest.tar.gz | with_sudo tar zx -C $wp_directory
    with_sudo chown -R www-data $wp_directory/wordpress
}

function get_servername() {
    if [[ $wp_url == "" ]]; then
        echo ""
    else
        echo "ServerName $wp_url"
    fi
}

function configure_apache() {
    # cat << EOF > /etc/apache2/sites-available/wordpress.conf
    cat << EOF > tmpfile
    <VirtualHost *:80>
    $(get_servername)
    DocumentRoot ${wp_directory}/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory ${wp_directory}/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
    </VirtualHost>
EOF

with_sudo mv tmpfile /etc/apache2/sites-available/wordpress.conf

with_sudo a2ensite wordpress
with_sudo a2enmod rewrite
with_sudo service apache2 restart

}

function create_db () {
    mysql_pw="test"
    cat << EOF |
    CREATE DATABASE wordpress;
    CREATE USER wordpress@localhost IDENTIFIED BY $mysql_pw;
    GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO wordpress@localhost;
    FLUSH PRIVILEGES;
    quit;
EOF
sudo mysql -u root -

}

function main() {
    #install_wp_packages
    download_wp
    configure_apache
}
main

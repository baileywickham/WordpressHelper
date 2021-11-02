#!/usr/bin/env bash

source utils.sh

wp_directory=/var/www/
wp_url=baileywickham.com

function install_wp_packages () {
    apt_update
    apt_install apache2 \
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

    }

function download_wp() {
    with_sudo chown www-data: $wp_directory
    curl https://wordpress.org/latest.tar.gz | with_sudo -u www-data tar zx -C $wp_directory
}

function configure_apache() {
    cat << EOF > /etc/apache2/sites-available/wordpress.conf
    <VirtualHost *:80>
    ServerName ${wp_url}
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

with_sudo a2ensite wordpress
with_sudo a2enmod rewrite
with_sudo service apache2 restart

}

function main() {
    install_wp_packages
    download_wp
    configure_apache
}
main

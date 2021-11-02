#!/usr/bin/env bash

source utils.sh

wp_directory=/var/www/
wp_url=""

function install_wp_packages () {
    apt_update
    apt_install apt_utils \
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

function download_wp() {
    with_sudo chown www-data: $wp_directory
    curl https://wordpress.org/latest.tar.gz | with_sudo -u www-data tar zx -C $wp_directory
}

function get_servername() {
    if [[ $wp_url == "" ]];
        echo ""
    else
        echo "ServerName $wp_url"
    fi
}

function configure_apache() {
    # cat << EOF > /etc/apache2/sites-available/wordpress.conf
    cat << EOF > /__tmp
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
with_sudo mv __tmp /etc/apache2/sites-available/wordpress.conf

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

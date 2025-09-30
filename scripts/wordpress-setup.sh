#!/bin/bash

# WordPress Setup Script for Azure Ubuntu VM
set -e

echo "=== Starting WordPress Setup ==="

# Update system
apt-get update
apt-get upgrade -y

# Install Apache, PHP, MySQL
apt-get install -y \
    apache2 \
    mysql-server \
    php \
    php-mysql \
    libapache2-mod-php \
    php-cli \
    php-curl \
    php-json \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip

# Start and enable services
systemctl start apache2
systemctl enable apache2
systemctl start mysql
systemctl enable mysql

# Download and setup WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /var/www/html/

# Set permissions
chown -R www-data:www-data /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# Create WordPress config
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

# Configure MySQL
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Update WordPress config
sed -i "s/database_name_here/wordpress/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/wpuser/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/wppassword/" /var
#!/bin/bash
# WordPress Manual Setup Script

set -e

echo "=== Manual WordPress Setup ==="

# Update system
sudo apt update
sudo apt upgrade -y

# Install LAMP stack
sudo apt install -y \
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

# Start services
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start mysql
sudo systemctl enable mysql

# Download WordPress
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /var/www/html/

# Set permissions
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Configure MySQL
sudo mysql -e "CREATE DATABASE IF NOT EXISTS wordpress;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppassword123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Create WordPress config
sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

# Update config with database details
sudo sed -i "s/database_name_here/wordpress/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/username_here/wpuser/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/password_here/wppassword123/" /var/www/html/wordpress/wp-config.php

# Configure Apache
sudo cat > /etc/apache2/sites-available/wordpress.conf << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/wordpress
    ServerName localhost

    <Directory /var/www/html/wordpress>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo a2dissite 000-default.conf
sudo systemctl restart apache2

echo "=== WordPress Setup Completed ==="
echo "WordPress should be available at: http://$(curl -s ifconfig.me)"
echo "MySQL Database: wordpress"
echo "MySQL User: wpuser"
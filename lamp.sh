#!/bin/bash

# Define MySQL database credentials
DB_NAME="laravel_app"
DB_USER="laravel_user"
DB_PASSWORD="laravel_password"

# Update package lists
update_packages() {
    sudo apt update -y
}

# Install Apache web server
install_apache() {
    sudo apt install -y apache2
    sudo a2enmod rewrite
}

# Install MySQL server and client
install_mysql() {
    sudo apt install -y mysql-server mysql-client
}

# Add PHP Ondrej repository and install PHP 8.2 and necessary extensions
install_php() {
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt update
    sudo apt install -y php8.2 php8.2-{curl,dom,mbstring,xml,mysql}
}

# Install zip and unzip utilities
install_zip_utils() {
    sudo apt install -y zip unzip
}

# Install composer
install_composer() {
    cd /usr/bin
    sudo curl -sS https://getcomposer.org/installer | sudo php
    sudo mv composer.phar composer
}

# Clone Laravel repository and install dependencies
install_laravel() {
    cd /var/www/
    sudo git clone https://github.com/laravel/laravel.git
    sudo chown -R $USER:$USER /var/www/laravel
    cd laravel/
    composer install --optimize-autoloader --no-dev
    composer update
    # Copy content of default .env file to .env
    sudo cp .env.example .env
    # Change ownership of storage and bootstrap/cache directories to www-data user
    sudo chown -R www-data storage
    sudo chown -R www-data bootstrap/cache
}

# Configure Apache Virtual Host
configure_virtual_host() {
    cd /etc/apache2/sites-available/
    sudo touch latest.conf
    sudo tee /etc/apache2/sites-available/latest.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/laravel/public

    <Directory /var/www/laravel>
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/laravel-error.log
    CustomLog ${APACHE_LOG_DIR}/laravel-access.log combined
</VirtualHost>
EOF
# Enable the latest.conf site and disable the default site
    sudo a2ensite latest.conf
    sudo a2dissite 000-default.conf
}

# Restart Apache server
restart_apache() {
    sudo systemctl restart apache2
}

# Create MySQL database and user
create_database() {
    sudo mysql -uroot -e "CREATE DATABASE $DB_NAME;"
    sudo mysql -uroot -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
}

# Modify .env file to use MySQL
modify_env_file() {
    cd /var/www/laravel
    sudo sed -i "23 s/^#//g" /var/www/laravel/.env
    sudo sed -i "24 s/^#//g" /var/www/laravel/.env
    sudo sed -i "25 s/^#//g" /var/www/laravel/.env
    sudo sed -i "26 s/^#//g" /var/www/laravel/.env
    sudo sed -i "27 s/^#//g" /var/www/laravel/.env
    sudo sed -i '22 s/=sqlite/=mysql/' /var/www/laravel/.env
    sudo sed -i '23 s/=127.0.0.1/=localhost/' /var/www/laravel/.env
    sudo sed -i '24 s/=3306/=3306/' /var/www/laravel/.env
    sudo sed -i '25 s/=laravel/=laravel_app/' /var/www/laravel/.env
    sudo sed -i '26 s/=root/=laravel_user/' /var/www/laravel/.env
    sudo sed -i '27 s/=/=laravel_password/' /var/www/laravel/.env
}

# Generate application key, create storage link, run migrations and seed database
initialize_laravel() {
    cd /var/www/laravel
    sudo php artisan key:generate
    sudo php artisan storage:link
    sudo php artisan migrate
    sudo php artisan db:seed
    restart_apache
}

# Main function
main() {
    update_packages && \
    install_apache && \
    install_mysql && \
    install_php && \
    install_zip_utils && \
    install_composer && \
    install_laravel && \
    configure_virtual_host && \
    restart_apache && \
    create_database && \
    modify_env_file && \
    initialize_laravel

    # Check the exit status of the last command
    if [ $? -eq 0 ]; then
        echo "SUCCESS!!"
    else
        echo "FAILURE: Some steps failed. Please check the logs for details."
    fi
}

# Call main function
main
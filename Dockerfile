FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Arguments injected via Coolify environment variables
ARG openemr_version
ARG domain
ARG mariadb_root_password
ARG openemr_db_user
ARG openemr_db_pass
ARG openemr_db_name

ENV web_root=/var/www/${domain}


# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    apache2 mariadb-server mariadb-client \
    php php-mysql php-cli php-gd php-curl php-xml php-mbstring php-soap \
    git unzip curl composer nodejs npm openssl \
    certbot python3-certbot-apache python3-pymysql

# Create web root
RUN mkdir -p ${web_root}

# Clone OpenEMR source code
RUN git clone --depth 1 --branch ${openemr_version} https://github.com/sivehost/openemrv703.git ${web_root}

# Set working directory
WORKDIR ${web_root}

# Install PHP and JS dependencies
RUN composer install --no-dev && \
    npm install && \
    npm run build

# Inject OpenEMR admin config with ENV vars
RUN mkdir -p ${web_root}/sites/default && \
    echo "<?php\n\
    //  OpenEMR\n\
    //  MySQL Config\n\n\
    global \$disable_utf8_flag;\n\
    \$disable_utf8_flag = false;\n\n\
    \$host   = 'localhost';\n\
    \$port   = '3306';\n\
    \$login  = '${openemr_db_user}';\n\
    \$pass   = '${openemr_db_pass}';\n\
    \$dbase  = '${openemr_db_name}';\n\
    \$db_encoding    = 'utf8mb4';\n\n\
    \$sqlconf = array();\n\
    global \$sqlconf;\n\
    \$sqlconf[\"host\"] = \$host;\n\
    \$sqlconf[\"port\"] = \$port;\n\
    \$sqlconf[\"login\"] = \$login;\n\
    \$sqlconf[\"pass\"] = \$pass;\n\
    \$sqlconf[\"dbase\"] = \$dbase;\n\
    \$sqlconf[\"db_encoding\"] = \$db_encoding;\n\n\
    //////////////////////////\n\
    //////////////////////////\n\
    //////////////////////////\n\
    //////DO NOT TOUCH THIS///\n\
    \$config = 1; /////////////\n\
    //////////////////////////\n\
    //////////////////////////\n\
    //////////////////////////\n\
    ?>" > ${web_root}/sites/default/sqlconf.php && \
    chown www-data:www-data ${web_root}/sites/default/sqlconf.php


# Set proper ownership
RUN chown -R www-data:www-data ${web_root}

# Enable Apache modules and virtual host
RUN a2enmod rewrite ssl && \
    printf "<VirtualHost *:80>\n\
    ServerName ${domain}\n\
    DocumentRoot ${web_root}\n\
    <Directory ${web_root}>\n\
        Options FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>\n" > /etc/apache2/sites-available/${domain}.conf && \
    a2ensite ${domain} && \
    echo "ServerName ${domain}" >> /etc/apache2/apache2.conf
    

# Optional: MariaDB setup — assumes external MariaDB is used in production
# Can be removed if using Coolify's managed MariaDB or separate container
# NOTE: service mysql is not persistent in Dockerfile RUN steps
COPY sql/openemrdb.sql /tmp/openemrdb.sql
RUN service mysql start && \
    mysql -e "SET GLOBAL sql_mode = '';" && \
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${openemr_db_name};" && \
    mysql -u root ${openemr_db_name} < /tmp/openemrdb.sql || echo "Skipping DB import"

# Expose ports for Apache
EXPOSE 80 443

# Start Apache in foreground
CMD ["apachectl", "-D", "FOREGROUND"]

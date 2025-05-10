FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Arguments injected via Coolify environment variables
ARG openemr_version
ARG domain
ARG web_root=/var/www/${domain}
ARG mariadb_root_password
ARG openemr_db_user
ARG openemr_db_pass
ARG openemr_db_name

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

# Set proper ownership
RUN chown -R www-data:www-data ${web_root}

# Enable Apache modules and virtual host
RUN a2enmod rewrite ssl && \
    echo "<VirtualHost *:80>
    ServerName ${domain}
    DocumentRoot ${web_root}
    <Directory ${web_root}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/${domain}.conf && \
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

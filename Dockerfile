FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ARG openemr_version=master
ARG domain=apps2.frappe.africa
ARG web_root=/var/www/${domain}
ARG mariadb_root_password
ARG openemr_db_user
ARG openemr_db_pass
ARG openemr_db_name

# Install base packages
RUN apt update && apt upgrade -y && apt install -y \
    apache2 mariadb-server mariadb-client \
    php php-mysql php-cli php-gd php-curl php-xml php-mbstring php-soap \
    git unzip curl composer nodejs npm openssl \
    certbot python3-certbot-apache python3-pymysql

# Prepare DB and Apache
RUN mkdir -p ${web_root}

# Clone OpenEMR
RUN git clone --depth 1 --branch ${openemr_version} https://github.com/sivehost/openemrv703.git ${web_root}

# Composer & NPM
WORKDIR ${web_root}
RUN composer install --no-dev && npm install && npm run build

# Set permissions
RUN chown -R www-data:www-data ${web_root}

# Add Apache config
COPY apache/site.conf /etc/apache2/sites-available/${domain}.conf

# Enable Apache features
RUN a2enmod rewrite ssl && a2ensite ${domain} && echo "ServerName ${domain}" >> /etc/apache2/apache2.conf

# Preload OpenEMR DB (optional)
COPY sql/openemrdb.sql /tmp/openemrdb.sql
RUN service mysql start && \
    mysql -e "SET GLOBAL sql_mode = '';" && \
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${openemr_db_name};" && \
    mysql -u root ${openemr_db_name} < /tmp/openemrdb.sql

# Add certs (or allow Certbot to issue on startup)
COPY ssl/fullchain.pem /etc/letsencrypt/live/${domain}/fullchain.pem
COPY ssl/privkey.pem /etc/letsencrypt/live/${domain}/privkey.pem

EXPOSE 80 443

CMD service mysql start && apachectl -D FOREGROUND

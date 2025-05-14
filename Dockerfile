FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Arguments passed from docker-compose

ARG DOMAIN

ENV WEB_ROOT=/var/www/apps2.frappe.africa

# Install dependencies
RUN apt update && apt install -y \
    apache2 mariadb-client php php-mysql php-cli php-gd php-curl \
    php-xml php-mbstring php-soap git unzip curl composer nodejs npm

# Clone OpenEMR from your GitHub fork

COPY . /var/www/apps2.frappe.africa

WORKDIR ${WEB_ROOT}

# Install PHP and JS dependencies
RUN composer install --no-dev && \
    npm install && \
    npm run build

# Apache config
RUN a2enmod rewrite ssl && \
    echo "ServerName oe.bcoza.co.za" >> /etc/apache2/apache2.conf

# Add startup script
COPY docker-entrypoint.sh /usr/local/bin/startup.sh
COPY sql/openemrdb.sql /tmp/openemrdb.sql
RUN chmod +x /usr/local/bin/startup.sh

EXPOSE 80 443

CMD ["bash", "/usr/local/bin/startup.sh"]

#!/bin/bash
set -e

echo "Waiting for MariaDB at host '$MYSQL_HOST'..."

until mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e 'SELECT 1'; do
    sleep 30
done

if [[ ! -f /var/www/.import_done ]]; then
    echo "Importing database '$MYSQL_DATABASE'..."
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /tmp/openemrdb.sql

    echo "Updating Apache DocumentRoot..."
    sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/apps2.frappe.africa|' /etc/apache2/sites-available/000-default.conf

    echo "Adding Directory access block..."
    cat <<EOF >> /etc/apache2/sites-available/000-default.conf
<Directory /var/www/apps2.frappe.africa>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF

    # Set ownership
    chown -R www-data:www-data /var/www/apps2.frappe.africa

    # Set file permissions
    find /var/www/apps2.frappe.africa -type f -exec chmod 644 {} \;

    # Set directory permissions
    find /var/www/apps2.frappe.africa -type d -exec chmod 755 {} \;

    touch /var/www/.import_done
else
    echo "Import already completed. Skipping."
fi

echo "Starting Apache..."
exec apache2ctl -D FOREGROUND

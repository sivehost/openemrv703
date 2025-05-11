#!/bin/sh
set -e

echo "Waiting for DB..."
until mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1"; do
  sleep 2
done

echo "Checking if DB exists..."
if ! mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE ${MYSQL_DATABASE}"; then
  echo "Importing DB..."
  mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE ${MYSQL_DATABASE};"
  mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" "${MYSQL_DATABASE}" < sql/openemrdb.sql
fi

echo "Done!"

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

version: '3.8'
services:
  db:
    image: 'mariadb:10.11'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
      MYSQL_DATABASE: '${OPENEMR_DB_NAME}'
      MYSQL_USER: '${OPENEMR_DB_USER}'
      MYSQL_PASSWORD: '${OPENEMR_DB_PASS}'
    volumes:
      - 'db_data:/var/lib/mysql'
  openemr:
    image: 'openemr/openemr:${OPENEMR_VERSION}'
    restart: always
    depends_on:
      - db
    ports:
      - '8080'
      - '8443'
    environment:
      - 'OE_USER=${OPENEMR_DB_USER}'
      - 'OE_PASS=${OPENEMR_DB_PASS}'
      - 'OE_DB=${OPENEMR_DB_NAME}'
      - MYSQL_HOST=db
      - 'MYSQL_ROOT_PASS=${MYSQL_ROOT_PASSWORD}'
    volumes:
      - 'openemr_data:${web_root}'
      - './ssl:/etc/ssl/certs:ro'
    extra_hosts:
      - '${DOMAIN}:127.0.0.1'
volumes:
  db_data: null
  openemr_data: null

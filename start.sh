#!/bin/bash

set -eu

mkdir -p /app/data/public

if [ ! -f "/app/data/public/index.html" ]; then
    cp /app/code/index.html /app/data/public/index.html
fi

if [ ! -f "/app/data/apache2-app.conf" ]; then
    cp /app/code/apache2-app.conf /app/data/apache2-app.conf
fi

chown -R www-data:www-data /app/data /run/app

echo "Starting apache"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND

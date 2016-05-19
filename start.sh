#!/bin/bash

set -eu

mkdir -p /app/data

if [ ! -f "/app/data/index.html" ]; then
	cp /app/code/index.html /app/data/index.html
fi

chown -R www-data:www-data /app/data /run/app

echo "Starting apache"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND

#!/bin/bash

set -eu

mkdir -p /app/data
chown -R www-data:www-data /app/data /run/wordpress

echo "Starting apache"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND

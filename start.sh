#!/bin/bash

set -eu

mkdir -p /app/data/public /run/app /run/apache2

if [ ! -f "/app/data/public/index.html" ]; then
    cp /app/code/index.html /app/data/public/index.html
fi

if [ ! -f "/app/data/apache2-app.conf" ]; then
    cp /app/code/apache2-app.conf /app/data/apache2-app.conf
fi

sed -e "s@AuthLDAPURL .*@AuthLDAPURL ${LDAP_URL}/${LDAP_USERS_BASE_DN}?username??(objectclass=user)@" \
    -e "s@AuthLDAPBindDN .*@AuthLDAPBindDN ${LDAP_BIND_DN}@" \
    -e "s@AuthLDAPBindPassword .*@AuthLDAPBindPassword ${LDAP_BIND_PASSWORD}@" \
    -i /app/data/apache2-app.conf

chown -R www-data:www-data /app/data /run

echo "Cleanup apache pid"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"

echo "Starting supervisor"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i lamp
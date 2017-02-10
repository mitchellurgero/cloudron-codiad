#!/bin/bash

set -eu

mkdir -p /app/data/public /run/app /run/apache2

# check if any index file exists
for f in /app/data/public/index.*; do
    [ -e "$f" ] && echo "Do not override existing index file" || cp /app/code/index.html /app/data/public/index.html
    break
done

if [ ! -f "/app/data/php.ini" ]; then
    cp /etc/php/7.0/apache2/php.ini.orig /app/data/php.ini
fi

if [ ! -f "/app/data/apache2-app.conf" ]; then
    cp /app/code/apache2-app.conf /app/data/apache2-app.conf
fi

sed -e "s@AuthLDAPURL .*@AuthLDAPURL ${LDAP_URL}/${LDAP_USERS_BASE_DN}?username??(objectclass=user)@" \
    -e "s@AuthLDAPBindDN .*@AuthLDAPBindDN ${LDAP_BIND_DN}@" \
    -e "s@AuthLDAPBindPassword .*@AuthLDAPBindPassword ${LDAP_BIND_PASSWORD}@" \
    -i /app/data/apache2-app.conf

## hook for custom start script in /app/data/run.sh
if [ -f "/app/data/run.sh" ]; then
    /bin/bash /app/data/run.sh
fi

chown -R www-data:www-data /app/data /run

echo "Starting apache"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND

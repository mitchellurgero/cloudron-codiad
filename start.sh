#!/bin/bash

set -eu

mkdir -p /app/data/public /run/apache2 /run/proftpd /run/app

# check if any index file exists
for f in /app/data/public/index.*; do
    [ -e "$f" ] && echo "Do not override existing index file" || cp /app/code/index.php /app/data/public/index.php
    break
done

# cleanup for old apache2-app.conf
rm -f /app/data/apache2-app.conf

if [ ! -f "/app/data/php.ini" ]; then
    cp /etc/php/7.0/apache2/php.ini.orig /app/data/php.ini
fi

# SFTP_PORT can be unset to disable SFTP
disable_sftp="false"
if [[ -z "${SFTP_PORT:-}" ]]; then
    echo "SSH disabled"
    SFTP_PORT=29418 # arbitrary port to keep sshd happy
    disable_sftp="true"
else
    sed -e "s,##SERVER_NAME,${APP_DOMAIN}," \
        -e "s/##SFTP_PORT/${SFTP_PORT}/" \
        -e "s,##LDAP_URL,${LDAP_URL},g" \
        -e "s/##LDAP_BIND_DN/${LDAP_BIND_DN}/g" \
        -e "s/##LDAP_BIND_PASSWORD/${LDAP_BIND_PASSWORD}/g" \
        -e "s/##LDAP_USERS_BASE_DN/${LDAP_USERS_BASE_DN}/g" \
        -e "s/##LDAP_UID/$(id -u www-data)/g" \
        -e "s/##LDAP_GID/$(id -g www-data)/g" \
        /app/code/proftpd.conf.template > /run/proftpd/proftpd.conf

    if [[ -f /app/data/public/index.php ]]; then
        sed -e "s,##SFTP_PORT,${SFTP_PORT}," \
            -e "s,##SFTP_DOMAIN,${APP_DOMAIN}," \
            -i /app/data/public/index.php
    fi
fi

if [[ ! -f "/app/data/sftpd/ssh_host_ed25519_key" ]]; then
    echo "Generating ssh host keys"
    mkdir -p /app/data/sftpd
    ssh-keygen -qt rsa -N '' -f /app/data/sftpd/ssh_host_rsa_key
    ssh-keygen -qt dsa -N '' -f /app/data/sftpd/ssh_host_dsa_key
    ssh-keygen -qt ecdsa -N '' -f /app/data/sftpd/ssh_host_ecdsa_key
    ssh-keygen -qt ed25519 -N '' -f /app/data/sftpd/ssh_host_ed25519_key
else
    echo "Reusing existing host keys"
fi

chmod 0600 /app/data/sftpd/*_key
chmod 0644 /app/data/sftpd/*.pub

## hook for custom start script in /app/data/run.sh
if [ -f "/app/data/run.sh" ]; then
    /bin/bash /app/data/run.sh
fi

chown -R www-data:www-data /app/data /run/apache2 /run/proftpd /run/app

echo "Starting supervisord"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i Lamp

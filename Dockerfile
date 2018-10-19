FROM cloudron/base:1.0.0@sha256:147a648a068a2e746644746bbfb42eb7a50d682437cead3c67c933c546357617

RUN mkdir -p /app/code /run/app/sessions
WORKDIR /app/code

RUN apt-get update && apt-get install -y php libapache2-mod-php crudini \
    php-redis \
    php-bcmath \
    php-bz2 \
    php-curl \
    php-date \
    php-dba \
    php-enchant \
    php-gd \
    php-geoip \
    php-gettext \
    php-imap \
    php-json \
    php-log \
    php-mbstring \
    php-mime-type \
    php-mysql \
    php-readline \
    php-soap \
    php-sql-formatter \
    php-sqlite3 \
    php-tcpdf \
    php-timer \
    php-twig \
    php-uuid \
    php-validate \
    php-xml \
    php-xml-svg \
    php-yac \
    php-zip \
    proftpd proftpd-mod-ldap \
    cron \
    apache2-dev \
    build-essential \
    && rm -rf /var/cache/apt /var/lib/apt/lists /etc/ssh_host_*

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
COPY apache/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
ADD apache/lamp.conf /app/code/lamp.conf
RUN ln -s /run/apache2/lamp.conf /etc/apache2/sites-enabled/lamp.conf
RUN echo "Listen 80" > /etc/apache2/ports.conf
RUN a2enmod rewrite authnz_ldap headers

# configure mod_php
RUN crudini --set /etc/php/7.2/apache2/php.ini PHP upload_max_filesize 64M && \
    crudini --set /etc/php/7.2/apache2/php.ini PHP post_max_size 64M && \
    crudini --set /etc/php/7.2/apache2/php.ini PHP memory_limit 128M && \
    crudini --set /etc/php/7.2/apache2/php.ini Session session.save_path /run/app/sessions && \
    crudini --set /etc/php/7.2/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.2/apache2/php.ini Session session.gc_divisor 100

RUN mv /etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini.orig && ln -sf /app/data/php.ini /etc/php/7.2/apache2/php.ini

# install RPAF module to override HTTPS, SERVER_PORT, HTTP_HOST based on reverse proxy headers
# https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-as-a-web-server-and-reverse-proxy-for-apache-on-one-ubuntu-16-04-server
RUN mkdir /app/code/rpaf && \
    curl -L https://github.com/gnif/mod_rpaf/tarball/669c3d2ba72228134ae5832c8cf908d11ecdd770 | tar -C /app/code/rpaf -xz --strip-components 1 -f -  && \
    cd /app/code/rpaf && \
    make && \
    make install && \
    rm -rf /app/code/rpaf

# configure rpaf
RUN echo "LoadModule rpaf_module /usr/lib/apache2/modules/mod_rpaf.so" > /etc/apache2/mods-available/rpaf.load && a2enmod rpaf

# phpMyAdmin
RUN mkdir -p /app/code/phpmyadmin && \
    curl -L https://files.phpmyadmin.net/phpMyAdmin/4.8.1/phpMyAdmin-4.8.1-english.tar.gz | tar zxvf - -C /app/code/phpmyadmin --strip-components=1
COPY phpmyadmin-config.inc.php /app/code/phpmyadmin/config.inc.php

# configure proftpd
ADD proftpd.conf /app/code/proftpd.conf.template

RUN rm -rf /var/log/proftpd && ln -s /run/proftpd /var/log/proftpd

# configure cron
RUN rm -rf /var/spool/cron && ln -s /run/cron /var/spool/cron
# clear out the crontab
RUN rm -f /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* && truncate -s0 /etc/crontab

# configure supervisor
ADD supervisor/ /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

# add code
COPY start.sh index.php /app/code/

# make cloudron exec sane
WORKDIR /app/data

CMD [ "/app/code/start.sh" ]

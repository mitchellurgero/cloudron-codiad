FROM cloudron/base:0.10.0
MAINTAINER Johannes Zellner <johannes@cloudron.io>

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
    php-mcrypt \
    php-mime-type \
    php-mysql \
    php-pdfparser \
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
    php-xml-parser \
    php-xml-svg \
    php-yac \
    php-zip \
    proftpd proftpd-mod-ldap \
    && rm -rf /var/cache/apt /var/lib/apt/lists /etc/ssh_host_*

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
RUN sed -e "s,MaxSpareServers[^:].*,MaxSpareServers 5," -i /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
RUN echo "Listen 80" > /etc/apache2/ports.conf
RUN a2enmod rewrite

# configure mod_php
RUN crudini --set /etc/php/7.0/apache2/php.ini PHP upload_max_filesize 8M && \
    crudini --set /etc/php/7.0/apache2/php.ini PHP post_max_size 8M && \
    crudini --set /etc/php/7.0/apache2/php.ini PHP memory_limit 64M && \
    crudini --set /etc/php/7.0/apache2/php.ini Session session.save_path /run/app/sessions

RUN mv /etc/php/7.0/apache2/php.ini /etc/php/7.0/apache2/php.ini.orig && ln -sf /app/data/php.ini /etc/php/7.0/apache2/php.ini

# configure site
COPY apache2-app.conf /etc/apache2/sites-enabled/app.conf

# configure proftpd
ADD proftpd.conf /app/code/proftpd.conf.template

RUN rm -rf /var/log/proftpd && ln -s /run/proftpd /var/log/proftpd

# configure supervisor
ADD supervisor/ /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

# add code
COPY start.sh index.php /app/code/

# make cloudron exec sane
WORKDIR /app/data

CMD [ "/app/code/start.sh" ]

FROM cloudron/base:0.9.0
MAINTAINER Johannes Zellner <johannes@cloudron.io>

RUN mkdir -p /app/code /run/app/sessions
WORKDIR /app/code

RUN apt-get update && apt-get install -y php libapache2-mod-php crudinit \
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
    php-mongodb \
    php-mysql \
    php-pdfparser \
    php-pgsql \
    php-readline \
    php-soap \
    php-sql-formatter \
    php-sqlite3 \
    php-ssh2 \
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
    && rm -r /var/cache/apt /var/lib/apt/lists


# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
RUN sed -e "s,MaxSpareServers[^:].*,MaxSpareServers 5," -i /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
RUN echo "Listen 8000" > /etc/apache2/ports.conf

RUN ln -sf /app/data/apache2-app.conf /etc/apache2/sites-available/app.conf
RUN ln -sf /etc/apache2/sites-available/app.conf /etc/apache2/sites-enabled/app.conf

RUN a2enmod rewrite dav dav_fs authnz_ldap

# configure mod_php
RUN crudini --set /etc/php/7.0/apache2/php.ini PHP upload_max_filesize 8M && \
    crudini --set /etc/php/7.0/apache2/php.ini PHP post_max_size 8M && \
    crudini --set /etc/php/7.0/apache2/php.ini PHP memory_limit 64M && \
    crudini --set /etc/php/7.0/apache2/php.ini Session session.save_path /run/app/sessions

ADD apache2-app.conf /app/code/apache2-app.conf
ADD index.html /app/code/index.html
ADD start.sh /app/code/start.sh

# make cloudron exec sane
WORKDIR /app/data

CMD [ "/app/code/start.sh" ]

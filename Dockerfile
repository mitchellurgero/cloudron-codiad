FROM cloudron/base:0.8.1
MAINTAINER Johannes Zellner <johannes@cloudron.io>

RUN mkdir -p /app/data /app/code /run/app/sessions
WORKDIR /app/data

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
RUN sed -e "s,MaxSpareServers[^:].*,MaxSpareServers 5," -i /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
RUN echo "Listen 8000" > /etc/apache2/ports.conf

# configure mod_php
RUN a2enmod php5 rewrite dav dav_fs authnz_ldap
RUN sed -e 's/upload_max_filesize = .*/upload_max_filesize = 8M/' \
        -e 's,;session.save_path.*,session.save_path = "/run/app/sessions",' \
        -i /etc/php5/apache2/php.ini

RUN ln -sf /app/data/apache2-app.conf /etc/apache2/sites-available/app.conf
RUN ln -sf /etc/apache2/sites-available/app.conf /etc/apache2/sites-enabled/app.conf

ENV PATH /usr/local/node-4.2.1/bin:$PATH

RUN cd /app/code && npm install ftpd

ADD apache2-app.conf /app/code/apache2-app.conf
ADD index.html /app/code/index.html
ADD start.sh /app/code/start.sh
ADD ftp.js /app/code/ftp.js

# configure supervisor
RUN sed -e 's,^logfile=.*$,logfile=/run/app/supervisord.log,' -i /etc/supervisor/supervisord.conf
ADD supervisor/ /etc/supervisor/conf.d/

CMD [ "/app/code/start.sh" ]

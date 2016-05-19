FROM cloudron/base:0.8.1
MAINTAINER Johannes Zellner <johannes@cloudron.io>

RUN mkdir -p /app/data /app/code /run/wordpress/sessions
WORKDIR /app/data

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
RUN sed -e "s,MaxSpareServers[^:].*,MaxSpareServers 5," -i /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
ADD apache2-wordpress.conf /etc/apache2/sites-available/wordpress.conf
RUN ln -sf /etc/apache2/sites-available/wordpress.conf /etc/apache2/sites-enabled/wordpress.conf
RUN echo "Listen 8000" > /etc/apache2/ports.conf

# configure mod_php
RUN a2enmod php5
RUN a2enmod rewrite
RUN sed -e 's/upload_max_filesize = .*/upload_max_filesize = 8M/' \
        -e 's,;session.save_path.*,session.save_path = "/run/wordpress/sessions",' \
        -i /etc/php5/apache2/php.ini

ADD installer.php /app/code/installer.php
ADD start.sh /app/code/start.sh

CMD [ "/app/code/start.sh" ]

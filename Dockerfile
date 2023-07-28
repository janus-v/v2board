FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
  nginx supervisor git zip unzip cron vim gettext-base procps \
  && rm -rf /var/lib/apt/lists/*


# Install the PHP extensions
RUN docker-php-ext-install fileinfo pcntl mysqli pdo pdo_mysql \
    && pecl install redis \
    && docker-php-ext-enable redis

# Remove the disabled functions
RUN sed -i 's/putenv,//g' /usr/local/etc/php/php.ini-production \
    && sed -i 's/proc_open,//g' /usr/local/etc/php/php.ini-production \
    && sed -i 's/pcntl_alarm,//g' /usr/local/etc/php/php.ini-production \
    && sed -i 's/pcntl_signal,//g' /usr/local/etc/php/php.ini-production

WORKDIR /www

# Install composer and dependencies
COPY server/install_composer.sh /www/install_composer.sh
COPY database /www/database
COPY artisan /www/artisan
COPY bootstrap /www/bootstrap
COPY composer.json /www/composer.json
COPY composer.lock /www/composer.lock

RUN bash install_composer.sh && php composer.phar install -v || echo "install composer dependencies. Failing is OKAY"

COPY server/etc/nginx /etc/nginx
COPY server/etc/crontabs/crontabs.conf /etc/crontabs/root

COPY . /www

RUN php composer.phar install -v

# COPY nginx/etc/php-fpm.conf /usr/local/etc/php-fpm.conf
# /usr/local/etc/php-fpm.conf
# COPY server/etc/php /etc/php
# COPY server/etc/php ./local/etc/php-fpm.d/www.conf

EXPOSE 80
EXPOSE 443

COPY server/entrypoint.sh /entrypoint.sh
COPY server/supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN chmod 755 /entrypoint.sh \
    && chmod -R 0777 /www/storage /www/config/theme/  /www/bootstrap/cache/

CMD ["/entrypoint.sh"]

#Usage: 
# docker buildx build --platform linux/x86_64  -t asians.azurecr.io/janus/v2board:latest .

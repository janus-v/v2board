#!/usr/bin/env bash

export NGINX_WEB_ROOT=${NGINX_WEB_ROOT:-'/www'}
export NGINX_PHP_FALLBACK=${NGINX_PHP_FALLBACK:-'/app.php'}
export NGINX_PHP_LOCATION=${NGINX_PHP_LOCATION:-'^/app\.php(/|$)'}
export NGINX_USER=${NGINX_USER:-'www-data'}
export NGINX_CONF=${NGINX_CONF:-'/etc/nginx/nginx.conf'}

export PHP_SOCK_FILE=${PHP_SOCK_FILE:-'/run/php.sock'}
export PHP_USER=${PHP_USER:-'www-data'}
export PHP_GROUP=${PHP_GROUP:-'www-data'}
export PHP_MODE=${PHP_MODE:-'0660'}
export PHP_FPM_CONF=${PHP_FPM_CONF:-'/usr/local/etc/php-fpm.d/www.conf'}

export APP_NAME=${APP_NAME:-'V2Board'}
export APP_DESCIPTION=${APP_DESCIPTION:-'P9M is best VPN in the world I have seen'}
export PUBLIC_APP_URL=${PUBLIC_APP_URL:-'http://localhost/#/dashboard'}
export APP_CURRENCY=${APP_CURRENCY:-'USD'}
export APP_CURRENCY_SYMBOL=${APP_CURRENCY_SYMBOL:-'$'}
export APP_SECURE_PATH=${APP_SECURE_PATH:-'secure_path_change_me'}

export APP_ENV=${APP_ENV:-'local'}
export APP_KEY=${APP_KEY:-'base64:aGVsbG93b3JsZGhlbGxvd29ybGRoZWxsb3dvcmxkaGVsbG93b3JsZA=='}
export APP_DEBUG=${DEBUG:-'false'}
export APP_URL=${APP_URL:-'http://localhost'}
export SUBSCRIPT_URL=${SUBSCRIPT_URL:-'http://localhost'}
export LOG_CHANNEL=${LOG_CHANNEL:-'stack'}
export DB_CONNECTION=${DB_CONNECTION:-'mysql'}
export DB_HOST=${DB_HOST:-'mysql'}
export DB_PORT=${DB_PORT:-'3306'}
export DB_DATABASE=${DB_DATABASE:-'v2board'}
export DB_USERNAME=${DB_USERNAME:-'v2board'}
export DB_PASSWORD=${DB_PASSWORD:-'v2board'}
export REDIS_HOST=${REDIS_HOST:-'redis'}
export REDIS_PASSWORD=${REDIS_PASSWORD:-'null'}
export REDIS_PORT=${REDIS_PORT:-'6379'}
export PUSHER_APP_KEY=${PUSHER_APP_KEY:-'base64:aGVsbG93b3JsZGhlbGxvd29ybGRoZWxsb3dvcmxkaGVsbG93b3JsZA=='}
export APP_ENV_CONF=${APP_ENV_CONF:-'/www/.env'}





#envsubst '${NGINX_WEB_ROOT} ${NGINX_PHP_FALLBACK} ${NGINX_PHP_LOCATION} ${NGINX_USER} ${NGINX_CONF} ${PHP_SOCK_FILE} ${PHP_USER} ${PHP_GROUP} ${PHP_MODE} ${PHP_FPM_CONF}' < /tmp/nginx.conf.tpl > $NGINX_CONF
#envsubst '${NGINX_WEB_ROOT} ${NGINX_PHP_FALLBACK} ${NGINX_PHP_LOCATION} ${NGINX_USER} ${NGINX_CONF} ${PHP_SOCK_FILE} ${PHP_USER} ${PHP_GROUP} ${PHP_MODE} ${PHP_FPM_CONF}' < /tmp/php-fpm.conf.tpl > $PHP_FPM_CONF
envsubst '${APP_NAME} ${APP_ENV} ${APP_KEY} ${APP_DEBUG} ${APP_URL} ${LOG_CHANNEL} ${DB_CONNECTION} ${DB_HOST} ${DB_PORT} ${DB_DATABASE} ${DB_USERNAME} ${DB_PASSWORD} ${REDIS_HOST} ${REDIS_PASSWORD} ${REDIS_PORT} ${PUSHER_APP_KEY}' < /www/server/env.tpl > $APP_ENV_CONF
./
envsubst '${APP_NAME} ${APP_DESCIPTION} ${PUBLIC_APP_URL} ${SUBSCRIPT_URL} ${APP_CURRENCY} ${APP_CURRENCY_SYMBOL} ${APP_SECURE_PATH}' < /www/server/v2board.php.tpl > /www/config/v2board.php


# Set error_log
sed -i 's/;php_admin_value\[error_log\] =/php_admin_value[error_log] = \/var\/log\/fpm-php.www.log/g' $PHP_FPM_CONF

# Check if the DEBUG environment variable is set to true
#DEBUG="true"

chmod 0777 /www/config/v2board.php

if [ "$DEBUG" = "true" ]; then
  # Enable log_errors
  sed -i 's/;php_admin_flag\[log_errors\] = .*/php_admin_flag[log_errors] = on/g' $PHP_FPM_CONF
  sed -i 's/;php_flag\[display_errors\] = .*/php_flag[display_errors] = on/g' $PHP_FPM_CONF
else
  # Disable log_errors
  sed -i 's/;php_admin_flag\[log_errors\] = .*/php_admin_flag[log_errors] = off/g' $PHP_FPM_CONF
  sed -i 's/;php_flag\[display_errors\] = .*/php_flag[display_errors] = off/g' $PHP_FPM_CONF
fi

# php_flag[display_errors] = on
# php_admin_value[error_log] = /var/log/fpm-php.www.log
# php_admin_flag[log_errors] = on
# php_admin_value[memory_limit] = 32M

/usr/bin/supervisord

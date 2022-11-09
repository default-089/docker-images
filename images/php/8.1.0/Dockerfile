FROM php:8.1.0-fpm

ENV TZ             Europe/Minsk
ENV USER_UID       0
ENV USER_GID       0
ENV APP_PATH       /var/www/app
ENV PHP_DIR_MODE   770
ENV MEMORY_LIMIT   256M
ENV POST_MAX_SIZE  16M

# FPM config
ENV WWW_CONF_PM     dynamic
ENV WWW_CONF_PM_MAX_CHILDREN          64
ENV WWW_CONF_PM_START_SERVERS         4
ENV WWW_CONF_PM_MIN_SPARE_SERVERS     4
ENV WWW_CONF_PM_MAX_SPARE_SERVERS     16
ENV WWW_CONF_PM_MAX_REQUESTS          0
ENV WWW_CONF_PM_PROCESS_IDLE_TIMEOUT  10s

# Additional config
ENV SUPERVISOR_STOP_WAIT_SECS  10
ENV MYSQL_CHECK_HOST     ""
ENV REDIS_CHECK_HOST     ""

# buildDeps:
#   libicu-dev - intl
#   libzip-dev - zip
#
# runtimeDeps:
#   libicu57 - intl
#   libzip4 - zip

RUN set -ex; \
    apt-get update; \
    buildDeps=" \
        libicu-dev \
        libzip-dev \
    "; \
    runtimeDeps=" \
        libzip4 \
        msmtp \
        cron \
        gosu \
        gettext-base \
        supervisor \
        netcat \
    "; \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y $buildDeps $runtimeDeps; \
    ln -s /usr/bin/msmtp /usr/sbin/sendmail; \
    docker-php-ext-install bcmath opcache pdo_mysql intl zip gd pcntl exif; \
    pecl install timezonedb redis; \
    docker-php-ext-enable timezonedb redis; \
    apt-get purge -y --auto-remove $buildDeps; \
    rm -rf /tmp/pear /var/lib/apt/lists/*;

COPY . /tmp/build

RUN set -ex; \
    mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini; \
    mv /tmp/build/entrypoint.sh /opt; \
    mv /tmp/build/entrypoint-cron.sh /opt; \
    mv /tmp/build/entrypoint-supervisor.sh /opt; \
    mv /tmp/build/wait_service.sh /opt; \
    \
    mkdir -p /var/php/log /var/php/tmp /var/php/sessions /var/php/upload;

VOLUME ["/var/www/app", "/var/php", "/etc/supervisor/conf.d"]

WORKDIR /var/www/app

EXPOSE 9000

ENTRYPOINT ["/opt/entrypoint.sh"]

CMD ["php-fpm", "-R"]

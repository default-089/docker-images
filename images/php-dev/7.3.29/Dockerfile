FROM dmitrakovich/php:7.3.29

ENV COMPOSER_ALLOW_SUPERUSER  1
ENV COMPOSER_MEMORY_LIMIT     -1
ENV COMPOSER_HOME             /tmp/.composer
ENV COMPOSER_CACHE_DIR        /var/cache/cache-composer
ENV COMPOSER_GITHUB_TOKEN     ""
ENV NPM_CACHE_DIR             /var/cache/cache-npm
ENV APP_DEV_HOST              ""
ENV NGINX_DEV_HOST            docker-proxy-nginx
ENV BITBUCKET_CONSUMER_KEY              ""
ENV BITBUCKET_CONSUMER_SECRET           ""
ENV PACKAGIST_USERNAME                  ""
ENV PACKAGIST_TOKEN                     ""

COPY 08-dev-custom.ini /tmp/build/ini/
COPY entrypoint-dev.sh /opt/

RUN set -ex; \
    pecl install xdebug; \
    docker-php-ext-enable xdebug; \
    rm -rf /tmp/pear; \
    \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y autoconf automake libtool make g++ unzip git rsync openssh-client; \
    rm -r /var/lib/apt/lists/*;

# See https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
RUN set -ex; \
    curl -fso composer-setup.php 'https://getcomposer.org/installer'; \
    curl -fs 'https://composer.github.io/installer.sha384sum' | sha384sum -c -; \
    php composer-setup.php --quiet --no-ansi --install-dir=/usr/local/bin --filename=composer; \
    rm composer-setup.php; \
    \
    curl -fso /usr/local/bin/dep 'https://deployer.org/releases/v6.7.3/deployer.phar'; \
    echo 'a00dd2c9e09e8d809ae14ad695578181a177cea7 */usr/local/bin/dep' | sha1sum -c -; \
    chmod +x /usr/local/bin/dep; \
    \
    apt-get update; \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -; \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y nodejs;

VOLUME ["/var/cache/cache-composer", "/var/cache/cache-npm"]

ENTRYPOINT ["/opt/entrypoint-dev.sh"]

CMD ["php-fpm", "-R"]

# Dev php:8.1.0-fpm image

Image for using in development and CI.

Based on [php-8.1.0](../../php/8.1.0/) image.

## Additional php-libs

- xdebug

## Additional linux programs

- **composer**
- nodejs
- **npm**
- unzip
- git
- rsync
- openssh-client

## Available env-variables

In addition to env-variables from the parent image here are few new vars:

- `COMPOSER_GITHUB_TOKEN`: [token for **composer**](https://getcomposer.org/doc/articles/troubleshooting.md#api-rate-limit-and-oauth-tokens) to prevent issues with GitHub API rate limits (default `""`).
- `APP_DEV_HOST`, `NGINX_DEV_HOST`: variables for updating `/etc/hosts` inside the container, see details below (default `""` and `docker-proxy-nginx`). 

## Usage

In `docker-compose.yml`:

```yaml
services:
  php:
    image: dmitrakovich/php-dev:8.1.0
    container_name: php
    environment:
      TZ: Europe/Moscow
      USER_UID: 1000
      USER_GID: 1000
      COMPOSER_GITHUB_TOKEN: 9f4fba6da66f5abf4c08b2d9b36787bf6ffbad6c
    volumes:
      - ./data/php:/var/php
      - ../src:/var/www/app
      - ~/.composer/cache:/var/cache/cache-composer
      - ~/.npm:/var/cache/cache-npm
```

Given in this example paths `~/.composer/cache` and `~/.npm` allow to store 
composer/npm cache in the same default place on the host for all containers 
based on this image (for all apps).

## Extended usage

If you use this image in local environment, you probably may use hostname
like `my-app.localhost.tools` (which points to `127.0.0.1`) for the app.

In that case if your app tries to make http-request from php-container
to itself using that hostname, it fails. Because `my-app.localhost.tools`
points to the php-container while you need to send request to some **nginx**.

The solution is to update the `/etc/hosts` file by adding there lines which
will link that hostname with IP of the nginx-container. For that purpose
you should use `APP_DEV_HOST` and `NGINX_DEV_HOST` env. variables.

`APP_DEV_HOST` has to contain hostname of the app (without any `http://`).
Also, you can set here a number of hostnames separated by comma (,).

`NGINX_DEV_HOST` (default `docker-proxy-nginx`) must be the name of the 
container with Nginx (or other web-server) which serves requests to app's
hostname. That container must run at the moment when app's container starts,
and they both must be in the same docker-network.

Example, in `docker-compose.yml`:

```yaml
services:
  php:
    image: dmitrakovich/php-dev:8.1.0
    container_name: php
    environment:
      MYSQL_CHECK_HOST: mysql
      REDIS_CHECK_HOST: redis
      APP_DEV_HOST: my-app.localhost.tools,my-app-alias.localhost.tools
      NGINX_DEV_HOST: docker-proxy-nginx
    networks:
      - default
      - docker-proxy
```
# Base php:8.1.0-fpm image

Image for using in production.

It has additional entrypoints for using as **cron**-container and as
**supervisor**-container for **Laravel** queue.

## Additional php-libs

- bcmath
- opcache
- pdo_mysql
- intl
- zip
- gd
- redis
- pcntl
- exif
- imap

## Available env-variables

- `TZ`: container timezone (default `Europe/London`).
- `APP_PATH`: path with the app inside the container; used by `envsubst` for cron-entrypoint (default `/var/www/app`).
- `USER_UID`, `USER_GID`: user to run php-fpm main process and workers (default `0` which means root).
- `PHP_DIR_MODE`: chmod for directories created by the container inside the `/var/php` volume (default `770`).
- `MEMORY_LIMIT`, `POST_MAX_SIZE`: values for substitute in php-config (default `256m` and `16m`).
- `WWW_CONF_PM`, `WWW_CONF_PM_...`: variables for configuration **php-fpm**, see file [www/zz-www.conf](./www/zz-www.conf) for details.
- `SUPERVISOR_STOP_WAIT_SECS`: timeout before killing supervisored process, see details below (default `10`).
- `MYSQL_CHECK_HOST`, `REDIS_CHECK_HOST`: hosts to check when related services become available, see below (default `""` for both).

## Usage

In `docker-compose.yml`:

```yaml
services:
  php:
    image: dmitrakovich/php:8.1.0
    container_name: php
    restart: always
    depends_on:
      - mysql
      - redis
    environment:
      TZ: Europe/Moscow
      USER_UID: 1000
      USER_GID: 1000
      MYSQL_CHECK_HOST: mysql
      REDIS_CHECK_HOST: redis
    volumes:
      - ./data/php:/var/php
      - ../src:/var/www/app
```

It's recommended to run php-fpm as another user by passing `USER_UID` and 
`USER_GID` to prevent issues with permissions of files created by the app.

If that PHP-service depends on MySQL and/or Redis services, you may
pass their hosts (container names) by `MYSQL_CHECK_HOST` and `REDIS_CHECK_HOST`.
If these variables are set (one or both), PHP's entrypoint doesn't start 
its main process until those services become available.

> Note: It doesn't mean that container with PHP is not running while
> databases are unavailable. It means that PHP itself (or cron/supervisor,
> depending on entrypoint) doesn't run.

## Usage as Cron-service

In `docker-compose.yml`:

```yaml
services:
  cron:
    image: dmitrakovich/php:8.1.0
    container_name: cron
    restart: always
    init: true
    entrypoint: ["/opt/entrypoint-cron.sh", "/cron/crontab"]
    environment:
      TZ: Europe/Moscow
      USER_UID: 1000
      USER_GID: 1000
    volumes:
      - ./data/php:/var/php
      - ../src:/var/www/app
      - ./crontab:/cron/crontab
```

So here you have to mount the `crontab` file (or directory with that file)
into the container and pass the path to it as an argument of the entrypoint.

You can use `APP_PATH` (default `/var/www/app`) variable in the `crontab`
file, it will be substituted with real value within the entrypoint:

```
* * * * * /usr/local/bin/php ${APP_PATH}/artisan schedule:run >> /dev/null 2>&1
```

And it's also recommended to add the following tasks there:

```
0 5 * * * find /var/php/tmp -type f -mtime +7 -exec rm -f {} \; >/dev/null
0 6 * * * find /var/php/upload -type f -mtime +7 -exec rm -f {} \; >/dev/null
```

These commands will clean temp directories from old files.


## Usage as Supervisor-service

In `docker-compose.yml`:

```yaml
services:
  supervisor:
    image: dmitrakovich/php:8.1.0
    container_name: supervisor
    restart: always
    entrypoint: ["/opt/entrypoint-supervisor.sh"]
    stop_grace_period: ${SUPERVISOR_STOP_WAIT_SECS}s
    environment:
      TZ: Europe/Moscow
      USER_UID: 1000
      USER_GID: 1000
      SUPERVISOR_STOP_WAIT_SECS: ${SUPERVISOR_STOP_WAIT_SECS}
    volumes:
      - ./data/php:/var/php
      - ../src:/var/www/app
      - ./supervisor:/etc/supervisor/conf.d
```

Mounted within this example volume `/etc/supervisor/conf.d` has to be a 
directory with workers config. Also, you can mount single file only: 
`- ./supervisor/worker.conf:/etc/supervisor/conf.d/worker.conf`.

Any number of workers may be described in the same file, or you can 
use separate files for each worker.

It's recommended to use the following template for these files:

```ini
[program:worker-name]
process_name=%(program_name)s_%(process_num)02d
command=php %(ENV_APP_PATH)s/artisan queue:work
autostart=true
autorestart=true
stopwaitsecs=%(ENV_SUPERVISOR_STOP_WAIT_SECS)s
user=%(ENV_PHP_USER)s
numprocs=4
redirect_stderr=true
stdout_logfile=/var/php/log/worker.log
```

Variables `ENV_APP_PATH`, `ENV_PHP_USER` and `ENV_SUPERVISOR_STOP_WAIT_SECS`
will be resolved by **Supervisor** itself from environment variables
`APP_PATH`, `PHP_USER` and `SUPERVISOR_STOP_WAIT_SECS`.

`PHP_USER` is set by entrypoint and may be `root` or `php-user` (depends on
`USER_UID` passed to the container).

### Note about `SUPERVISOR_STOP_WAIT_SECS`

Usually queue jobs may take some time to complete, and you don't want them
to be interrupted when container stops.

When you stop the container it:
- sends `SIGTERM` signal to its main process (Supervisor);
- waits 10 seconds to let that process shut down gracefully;
- sends `SIGKILL` if the process is still running.

When Supervisor receives `SIGTERM` it does almost the same: sends that
signal to its subprocesses, waits 10 seconds while they stop, and if they don't - sends `SIGKILL`.

Due to **pcntl** php-extension **Laravel** worker is able to process
`SIGTERM` signal: it lets current job to finish and then stops itself.

So if container stops, current job gracefully finishes, and the next job
doesn't start. The only problem is that both Docker and Supervisor have
their timeouts of 10 sec after which job may be interrupted.

In the above examples these timeouts were set from the
`SUPERVISOR_STOP_WAIT_SECS` variable. For docker-container it's
`stop_grace_period` parameter (note about `s` at the end: that
parameter has to be a string like `10s`), for Supervisor it's
`stopwaitsecs` parameter.

So all that means that you must not forget that the value of
`SUPERVISOR_STOP_WAIT_SECS` has to be greater than the greatest
`timeout` of your jobs (or than `retry_after` value from redis-queue
config from Laravel).






#!/usr/bin/env bash

# Set container timezone
echo "${TZ}" >/etc/timezone
ln -sfn /usr/share/zoneinfo/${TZ} /etc/localtime

# Find/create php user
if [ "$USER_UID" -eq "0" ]; then
  export PHP_USER=root
else
  export PHP_USER=$(getent passwd "$USER_UID" | cut -d: -f1) # look for existing user with the given id
  if [ -z "$PHP_USER" ]; then
    export PHP_USER=php-user
    if ! id "$PHP_USER" >/dev/null 2>&1; then
      adduser --uid ${USER_UID} --disabled-password --gecos "" ${PHP_USER}
    fi
  fi
fi

RUN_AS="${USER_UID}:${USER_GID}"

# Deploy php config
fill_config() {
  local DIR_SRC="$1"
  local DIR_DST="$2"
  for FILE_SRC in "$DIR_SRC"/*; do
    if [ -f "$FILE_SRC" ]; then
      local FILE_DST=$DIR_DST${FILE_SRC#"$DIR_SRC"}
      mkdir -p "${FILE_DST%/*}" && touch "$FILE_DST"
      envsubst '${PHP_USER} ${TZ} ${MEMORY_LIMIT} ${POST_MAX_SIZE} ${WWW_CONF_PM} ${WWW_CONF_PM_MAX_CHILDREN} ${WWW_CONF_PM_START_SERVERS} ${WWW_CONF_PM_MIN_SPARE_SERVERS} ${WWW_CONF_PM_MAX_SPARE_SERVERS} ${WWW_CONF_PM_MAX_REQUESTS} ${WWW_CONF_PM_PROCESS_IDLE_TIMEOUT}' <"$FILE_SRC" >"$FILE_DST"
    fi
  done
  chown -R "${RUN_AS}" "${DIR_DST}"
}
fill_config /tmp/build/ini "${PHP_INI_DIR}/conf.d"
fill_config /tmp/build/www "${PHP_INI_DIR}/../php-fpm.d"

# Create runtime dirs
function check_and_create() {
  DIR="/var/php/$1"
  if [ ! -d "${DIR}" ]; then
    mkdir -p ${DIR}
  fi
  chmod ${PHP_DIR_MODE} ${DIR}
  chown ${RUN_AS} ${DIR}
}
check_and_create tmp
check_and_create sessions
check_and_create upload
check_and_create log

# Wait while MySQL and Redis services become available
source /opt/wait_service.sh
wait_service "$MYSQL_CHECK_HOST" 3306
wait_service "$REDIS_CHECK_HOST" 6379

if [ "$#" -ne 0 ]; then
  exec gosu "${RUN_AS}" "$@"
fi

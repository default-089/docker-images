#!/usr/bin/env bash

# Call parent's entrypoint
/opt/entrypoint.sh

# Config NPM
npm config set cache ${NPM_CACHE_DIR} --global

RUN_AS="${USER_UID}:${USER_GID}"

# Create runtime dirs
function check_and_create() {
  DIR="$1"
  if [ ! -d "${DIR}" ]; then
    mkdir -p ${DIR}
  fi
  chmod ${PHP_DIR_MODE} ${DIR}
  chown ${RUN_AS} ${DIR}
}
check_and_create ${COMPOSER_CACHE_DIR}
check_and_create ${NPM_CACHE_DIR}

# Config composer
chown -R "${RUN_AS}" "${COMPOSER_HOME}"
if [ ! -z "${COMPOSER_GITHUB_TOKEN}" ]; then
  gosu "${RUN_AS}" composer config -g github-oauth.github.com "${COMPOSER_GITHUB_TOKEN}"
fi
if [ ! -z "${BITBUCKET_CONSUMER_KEY}" ] && [ ! -z "${BITBUCKET_CONSUMER_SECRET}" ]; then
  echo '{"bitbucket-oauth":{"bitbucket.org":{"consumer-key":"'$BITBUCKET_CONSUMER_KEY'","consumer-secret":"'$BITBUCKET_CONSUMER_SECRET'"}}}' > ${COMPOSER_HOME}/auth.json
  chown -R "${RUN_AS}" "${COMPOSER_HOME}"
fi
if [ ! -z "${PACKAGIST_USERNAME}" ] && [ ! -z "${PACKAGIST_TOKEN}" ]; then
  gosu "${RUN_AS}" composer config --global --auth http-basic.repo.packagist.com "${PACKAGIST_USERNAME}" "${PACKAGIST_TOKEN}"
fi

# Add nginx-host to /etc/hosts to let the app make requests to itself
if [ ! -z "$NGINX_DEV_HOST" ]; then
  NGINX_IP=$(getent hosts $NGINX_DEV_HOST | awk '{ print $1 }')
  if [ ! -z "$NGINX_IP" ] && [ ! -z "$APP_DEV_HOST" ]; then
    # Assume that APP_DEV_HOST contains few hosts separated by comma ,
    for app_host in ${APP_DEV_HOST//,/ }; do
      echo "$NGINX_IP $app_host" >>/etc/hosts
    done
  fi
fi

if [ "$#" -ne 0 ]; then
  exec gosu "${RUN_AS}" "$@"
fi

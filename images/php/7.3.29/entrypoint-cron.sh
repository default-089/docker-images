#!/usr/bin/env bash

# Call main entrypoint
/opt/entrypoint.sh

# Get php user
if [ "$USER_UID" -eq "0" ]; then
  PHP_USER=root
else
  PHP_USER=php-user
fi

# Deploy crontab file
crontab="$1"
if ! [ -f "${crontab}" ]; then
  echo "Crontab file ${crontab} is not found"
  exit 1
fi
crontab_final=/crontab_final
envsubst '${APP_PATH}' <"$crontab" >"$crontab_final"

# Save env-cars to make them available for cron
declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

# Run cron
crontab -u ${PHP_USER} ${crontab_final}
exec cron -f

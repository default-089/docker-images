#!/usr/bin/env bash

# Call main entrypoint
/opt/entrypoint.sh

# Get php user
if [ "$USER_UID" -eq "0" ]; then
  export PHP_USER=root
else
  export PHP_USER=php-user
fi

# Run supervisord
exec /usr/bin/supervisord -n

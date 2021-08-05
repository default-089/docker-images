#!/usr/bin/env sh

calc() {
  awk "BEGIN { print $* }"
}

wait_service() {
  local HOST="$1"
  local PORT="$2"
  local TIMEOUT="$3"
  if [ -z "${HOST}" ]; then
    return
  fi
  if [ -z "${PORT}" ]; then
    return
  fi
  if [ -z "${TIMEOUT}" ]; then
    TIMEOUT=15
  fi

  local TRIES_PER_SEC=10
  local TRIES=$(calc $TIMEOUT \* $TRIES_PER_SEC)
  local WAIT_INTERVAL=$(calc 1 / $TRIES_PER_SEC)
  for i in $(seq $TRIES); do
    nc -z "$HOST" "$PORT" >/dev/null 2>&1
    result=$?
    if [ $result -eq 0 ]; then
      return
    fi
    sleep $WAIT_INTERVAL
  done
  echo "Waiting for $HOST:$PORT is timed out ($TIMEOUT sec)" >&2
  exit 1
}

export wait_service

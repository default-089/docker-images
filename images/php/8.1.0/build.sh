#!/usr/bin/env bash

TAG=dmitrakovich/php:8.1.0

IMAGE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CURRENT_DIR=$(pwd)
cd "${IMAGE_DIR}"

# Read CLI options:
# -a: build all parent images
# -p: push built images
OPTIND=1
ALL=0
PUSH=0
while getopts "a?p?:" opt; do
    case "$opt" in
    a) ALL=1
       ;;
    p) PUSH=1
       ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

# Fix chmod (just in case)
git update-index --chmod=+x ./build.sh
git update-index --chmod=+x ./entrypoint.sh
git update-index --chmod=+x ./entrypoint-cron.sh
git update-index --chmod=+x ./entrypoint-supervisor.sh
chmod +x ./entrypoint.sh
chmod +x ./entrypoint-cron.sh
chmod +x ./entrypoint-supervisor.sh

# Build image
docker build -t "${TAG}" ./

# Push image
if [ "$PUSH" == "1" ]; then
  docker login docker.io
  docker push "${TAG}"
fi

cd "${CURRENT_DIR}"
echo DONE
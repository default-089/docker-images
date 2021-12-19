#!/usr/bin/env bash

TAG=dmitrakovich/php-dev:8.1.0

PARENT_IMAGE_DIR=../../php/8.1.0

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
git update-index --chmod=+x ./entrypoint-dev.sh
chmod +x ./entrypoint-dev.sh

# Build/push parent images
if [ "$ALL" == "1" ]; then
  if [ "$PUSH" == "1" ]; then
    ${PARENT_IMAGE_DIR}/build.sh -ap
  else
    ${PARENT_IMAGE_DIR}/build.sh -a
  fi
fi

# Build image
docker build -t "${TAG}" ./

# Push image
if [ "$PUSH" == "1" ]; then
  docker login docker.io
  docker push "${TAG}"
fi

cd "${CURRENT_DIR}"
echo DONE
#!/usr/bin/env bash
#
# Usage:  ./nonitor.sh <config file>

set -x

config=$1

[ "$config" ] || exit 1

. ${config}

function healthcheck() {
  #Check if container is running
  state=$(docker inspect --format='{{json .State}}' docker-weblate_weblate_1 | jq -r .Status -)
  if [ "${state}" == "exited" ]; then
    echo "unhealthy"
    exit 1
  else
    docker inspect --format='{{json .State.Health}}' ${1} | jq -r ".Status" -
  fi
}

function restart() {
  cd $directory
  if [ -f docker-compose.yml ]; then
    # The best is to restart all orchestration
    docker-compose down
    sleep 5
    docker-compose up -d
  else
    # Restart only failed service
    docker restart $container
  fi
}

for x in ${watched}; do
   if [ "$(healthcheck $x)" == "unhealthy" ]; then
      restart $x
   fi
done

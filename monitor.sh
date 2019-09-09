#!/usr/bin/env bash
#
# Usage:  ./monitor.sh <config file>


config=$1


precheck(){
  if [ "$2" == "" ]; then
	echo "ERROR: $1 $2 does not exist!"
	exit 1
  fi

}

healthcheck() {
  #Check if container is running
  state=$(docker inspect --format='{{json .State}}' ${1} | jq -r .Status -)
  if [ "${state}" == "exited" ]; then
    echo "unhealthy"
    exit 1
  else
    docker inspect --format='{{json .State.Health}}' ${1} | jq -r ".Status" -
  fi
}

restart() {
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

precheck Config $config

. ${config}

precheck Directory $directory

precheck Watched $watched

# Main
for x in ${watched}; do
   if [ "$(healthcheck $x)" == "unhealthy" ]; then
      restart $x
   fi
done

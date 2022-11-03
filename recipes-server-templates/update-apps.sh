#!/bin/bash

# Script to run update docker apps

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DOCKER_COMPOSE="_docker_compose_"

SYNC_CONTAINER_IPS_SCRIPT="_sync_container_ips_script_"


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."

echo "$(date "+%d.%m.%Y %T") INFO: Getting latest images started."
docker compose -f ${DOCKER_COMPOSE} pull

echo "$(date "+%d.%m.%Y %T") INFO: Stopping apps."
docker compose -f ${DOCKER_COMPOSE} stop

echo "$(date "+%d.%m.%Y %T") INFO: Recreate container images and restarting apps."
docker compose -f ${DOCKER_COMPOSE} up -d --force-recreate
${SYNC_CONTAINER_IPS_SCRIPT}

echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

exit

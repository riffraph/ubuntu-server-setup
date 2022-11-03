#!/bin/bash

# Script to run update docker apps

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOCK_FILE="${SCRIPT_FOLDER}/run-apps.lock"

DOCKER_COMPOSE="_docker_compose_"

CLEAN_UP_SCRIPT="_clean_up_script_"
RUN_APPS_SCRIPT="_run_apps_script_"


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."

echo "$(date "+%d.%m.%Y %T") INFO: Getting latest images started."
docker compose -f ${DOCKER_COMPOSE} pull

echo "$(date "+%d.%m.%Y %T") INFO: Stopping apps."
docker compose -f ${DOCKER_COMPOSE} stop
${CLEAN_UP_SCRIPT}

echo "$(date "+%d.%m.%Y %T") INFO: Recreate container images and restarting apps."
${RUN_APPS_SCRIPT} -r


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

exit

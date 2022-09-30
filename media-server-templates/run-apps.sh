#!/bin/bash

# Script to run docker apps that are dependent on remote mounts to be available

# This is an alternative to setting a restart policy on the container to always

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOCK_FILE="${SCRIPT_FOLDER}/run-apps.lock"
MOUNT_CHECK_FILE="mountcheck"

DOCKER_COMPOSE="_docker_compose_"

MERGED_FOLDER="_merged_folder_"

SYNC_CONTAINER_IPS_SCRIPT="_sync_container_ips_script_"


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


echo "$(date "+%d.%m.%Y %T") INFO: Checking if remote mount is operational."
if [[ -f "${MERGED_FOLDER}/${MOUNT_CHECK_FILE}" ]]; then
    echo "$(date "+%d.%m.%Y %T") INFO: Check successful, remote mount is operating."
else
    echo "$(date "+%d.%m.%Y %T") CRITICAL: remote mount is not operational.  Stopping dockers."
    docker compose -f ${DOCKER_COMPOSE} stop
    exit
fi

# only start dockers once
if [[ -f "${LOCK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: dockers already started."
else
	touch ${LOCK_FILE}
	echo "$(date "+%d.%m.%Y %T") INFO: Starting dockers."
    docker compose -f ${DOCKER_COMPOSE} up -d

    # TODO: add logic to retry when a container fails to start

	${SYNC_CONTAINER_IPS_SCRIPT}
fi


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

exit

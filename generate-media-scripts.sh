#!/bin/bash

set -e


if [ $# -eq 0 ]
then
    echo "Specify a directory for the output"
    exit
fi


function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${CURRENT_FOLDER}/_media-scripts.sh"
}

OUTPUT_FOLDER=${1}
TEMPLATES_FOLDER="media-server-templates"
CURRENT_FOLDER=$(getCurrentDir)
DATA_ROOT_FOLDER="/mnt/user" # top level folder to organise the local, remote and merged folders under


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


includeDependencies

mkdir -p ${OUTPUT_FOLDER}

cp ${TEMPLATES_FOLDER}/sync-container-ips.sh ${OUTPUT_FOLDER}
prepSyncContainerIpsScript ${OUTPUT_FOLDER} $PWD

cp ${TEMPLATES_FOLDER}/set-permissions.sh ${OUTPUT_FOLDER}
prepSetPermissionsScript ${OUTPUT_FOLDER}/set-permissions.sh ${DATA_ROOT_FOLDER}

cp ${TEMPLATES_FOLDER}/run-apps.sh ${OUTPUT_FOLDER}
prepRunAppsScript ${OUTPUT_FOLDER}/run-apps.sh ${DATA_ROOT_FOLDER} ${OUTPUT_FOLDER}/media-docker-compose.yaml ${OUTPUT_FOLDER}/sync-container-ips.sh

cp ${TEMPLATES_FOLDER}/update-apps.sh ${OUTPUT_FOLDER}
prepUpdateAppsScript ${OUTPUT_FOLDER}/update-apps.sh ${DATA_ROOT_FOLDER} ${OUTPUT_FOLDER}/media-docker-compose.yaml ${OUTPUT_FOLDER}/clean-up.sh

cp ${TEMPLATES_FOLDER}/clean-up.sh ${OUTPUT_FOLDER}


chmod +x ${OUTPUT_FOLDER}/sync-container-ips.sh
chmod +x ${OUTPUT_FOLDER}/set-permissions.sh
chmod +x ${OUTPUT_FOLDER}/run-apps.sh
chmod +x ${OUTPUT_FOLDER}/update-apps.sh
chmod +x ${OUTPUT_FOLDER}/clean-up.sh


echo "$(date "+%d.%m.%Y %T") INFO: ${0} completed."

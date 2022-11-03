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
    source "${CURRENT_FOLDER}/_recipes-scripts.sh"
}

OUTPUT_FOLDER=${1}
TEMPLATES_FOLDER="recipes-server-templates"
CURRENT_FOLDER=$(getCurrentDir)

echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


includeDependencies

mkdir -p ${OUTPUT_FOLDER}

cp ${TEMPLATES_FOLDER}/sync-container-ips.sh ${OUTPUT_FOLDER}
prepSyncContainerIpsScript ${OUTPUT_FOLDER} $PWD

cp ${TEMPLATES_FOLDER}/backup.sh ${OUTPUT_FOLDER}
prepBackupScript ${OUTPUT_FOLDER}/backup.sh /mnt/user/local/backup .env

cp ${TEMPLATES_FOLDER}/update-apps.sh ${OUTPUT_FOLDER}
prepUpdateAppsScript ${OUTPUT_FOLDER}/update-apps.sh ${OUTPUT_FOLDER}/recipes-docker-compose.yaml ${OUTPUT_FOLDER}/sync-container-ips.sh

chmod +x ${OUTPUT_FOLDER}/sync-container-ips.sh
chmod +x ${OUTPUT_FOLDER}/backup.sh
chmod +x ${OUTPUT_FOLDER}/update-apps.sh


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."

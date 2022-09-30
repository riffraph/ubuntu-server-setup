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
    source "${CURRENT_FOLDER}/_data-scripts.sh"
}

OUTPUT_FOLDER=${1}
TEMPLATES_FOLDER="data-templates"
CURRENT_FOLDER=$(getCurrentDir)
DATA_ROOT_FOLDER="/mnt/user" # top level folder to organise the local, remote and merged folders under


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


includeDependencies

mkdir -p ${OUTPUT_FOLDER}

cp ${TEMPLATES_FOLDER}/data-overview.sh ${OUTPUT_FOLDER}
prepOverviewScript ${OUTPUT_FOLDER}/data-overview.sh ${DATA_ROOT_FOLDER} ${OUTPUT_FOLDER}/rclone.conf ${OUTPUT_FOLDER}

cp ${TEMPLATES_FOLDER}/mount-remote.sh ${OUTPUT_FOLDER}
prepMountScript ${OUTPUT_FOLDER}/mount-remote.sh ${DATA_ROOT_FOLDER} ${OUTPUT_FOLDER}/rclone.conf

cp ${TEMPLATES_FOLDER}/upload-to-remote.sh ${OUTPUT_FOLDER}
prepUploadScript ${OUTPUT_FOLDER}/upload-to-remote.sh ${DATA_ROOT_FOLDER} ${OUTPUT_FOLDER}/rclone.conf

cp ${TEMPLATES_FOLDER}/manage-cache.sh ${OUTPUT_FOLDER}
prepManageCacheScript ${OUTPUT_FOLDER}/manage-cache.sh ${DATA_ROOT_FOLDER} ${OUTPUT_FOLDER}/rclone.conf ${OUTPUT_FOLDER}

cp ${TEMPLATES_FOLDER}/clean-up.sh ${OUTPUT_FOLDER}

chmod +x ${OUTPUT_FOLDER}/data-overview.sh
chmod +x ${OUTPUT_FOLDER}/mount-remote.sh
chmod +x ${OUTPUT_FOLDER}/upload-to-remote.sh
chmod +x ${OUTPUT_FOLDER}/clean-up.sh
chmod +x ${OUTPUT_FOLDER}/manage-cache.sh


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

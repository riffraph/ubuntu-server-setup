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
    source "${currentDir}/_media-scripts.sh"
}

outputDir=${1}
templatesDir="media-server-templates"
currentDir=$(getCurrentDir)
includeDependencies

mkdir -p ${outputDir}

cp ${templatesDir}/sync-container-ips.sh ${outputDir}
prepMaintenanceScripts ${outputDir} $PWD

cp ${templatesDir}/get-data-overview.sh ${outputDir}
prepOverviewScript ${outputDir}/get-data-overview.sh

cp ${templatesDir}/manage-cache.sh ${outputDir}
prepManageCacheScript ${outputDir}/manage-cache.sh

cp ${templatesDir}/rclone_mount ${outputDir}
prepMountScript ${outputDir}/rclone_mount

cp ${templatesDir}/rclone_upload ${outputDir}
prepUploadScript ${outputDir}/rclone_upload

cp ${templatesDir}/set-permissions.sh ${outputDir}
prepSetPermissionsScript ${outputDir}/set-permissions.sh

chmod +x ${outputDir}/sync-container-ips.sh
chmod +x ${outputDir}/get-data-overview.sh
chmod +x ${outputDir}/manage-cache.sh
chmod +x ${outputDir}/rclone_mount
chmod +x ${outputDir}/rclone_upload
chmod +x ${outputDir}/set-permissions.sh

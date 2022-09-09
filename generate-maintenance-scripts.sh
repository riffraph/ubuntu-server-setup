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
    source "${currentDir}/_setup-data.sh"
}


outputDir=${1}
templatesDir="templates"
currentDir=$(getCurrentDir)
includeDependencies

mkdir -p ${outputDir}

cp ${templatesDir}/get-data-overview.sh ${outputDir}
prepOverviewScript ${outputDir}/get-data-overview.sh

cp ${templatesDir}/rclone_mount ${outputDir}
prepMountScript ${outputDir}/rclone_mount

cp ${templatesDir}/rclone_upload ${outputDir}
prepUploadScript ${outputDir}/rclone_upload

chmod +x ${outputDir}/get-data-overview.sh
chmod +x ${outputDir}/rclone_mount
chmod +x ${outputDir}/rclone_upload
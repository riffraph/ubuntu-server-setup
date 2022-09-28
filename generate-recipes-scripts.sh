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
    source "${currentDir}/_recipes-scripts.sh"
}

outputDir=${1}
templatesDir="recipes-server-templates"
currentDir=$(getCurrentDir)
includeDependencies

mkdir -p ${outputDir}

cp ${templatesDir}/sync-container-ips.sh ${outputDir}
prepMaintenanceScripts ${outputDir} $PWD

chmod +x ${outputDir}/sync-container-ips.sh

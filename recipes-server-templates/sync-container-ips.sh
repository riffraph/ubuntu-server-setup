#!/bin/bash

# this script is intended to be used when the container ip address changes

set -e

function includeDependencies() {
    source "${LIB_FOLDER}/_setup-network.sh"
}

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIB_FOLDER="_lib_folder_"
CONFIG_FILE="config"


includeDependencies

function syncContainerIps() {
    local externalPort=${1}
    local internalPort=${2}

    recipesProxyAddr=$(getContainerIPAddress "recipes-proxy")
    recipesWebAddr=$(getContainerIPAddress "recipes-web")
    recipesDBAddr=$(getContainerIPAddress "recipes-db")

    resetForwardPortRule "inbound" ${externalPort} ${recipesProxyAddr} "tcp" ${internalPort}

    addIPToZone "containers" ${recipesProxyAddr}
    addIPToZone "containers" ${recipesWebAddr}
    addIPToZone "containers" ${recipesDBAddr}
}


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


if grep -q "recipesPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE}; then
    recipesPort=$(grep "recipesPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE} | sed 's/.*=//')
else
    recipesPort=100
fi

syncContainerIps ${recipesPort} 80


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

#!/bin/bash

# this script is intended to be used when the container ip address changes

set -e

function includeDependencies() {
    source "${libDir}/_setup-network.sh"
}

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
libDir=_libDir_
configFile="config"
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

if grep -q "recipesPort=" ${scriptDir}/${configFile}; then
    recipesPort=$(grep "recipesPort=" ${scriptDir}/${configFile} | sed 's/.*=//')
else
    recipesPort=100
fi

syncContainerIps ${recipesPort} 80
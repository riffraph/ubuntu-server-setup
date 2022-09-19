#!/bin/bash

# this script is intended to be used when the container ip address changes

set -e

function includeDependencies() {
    source "${libDir}/_setup-network.sh"
}

libDir=_libDir_
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

syncContainerIps 100 80
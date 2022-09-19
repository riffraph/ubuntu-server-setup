#!/bin/bash

# this script is intended to be used when the container ip address changes

set -e

function includeDependencies() {
    source "${libDir}/_setup-network.sh"
}

libDir=_libDir_
includeDependencies


function main() {
    externalPort=100
    internalPort=80    

    recipesProxyAddr=$(getContainerIPAddress "recipes-proxy")
    recipesWebAddr=$(getContainerIPAddress "recipes-web")
    recipesDBAddr=$(getContainerIPAddress "recipes-db")

    resetForwardPortRule "inbound" ${externalPort} ${recipesProxyAddr} "tcp" ${internalPort}

    addIPToZone "containers" ${recipesProxyAddr}
    addIPToZone "containers" ${recipesWebAddr}
    addIPToZone "containers" ${recipesDBAddr}
}


main
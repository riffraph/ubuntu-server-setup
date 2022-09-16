#!/bin/bash

# this script is intended to be used when the container ip address changes

set -e

function includeDependencies() {
    source "${libDir}/_setup-network.sh"
}

libDir=_libDir_
includeDependencies


function main() {
    recipesPort=100

    recipesAddr=$(getContainerIPAddress "recipes-nginx")

    resetForwardPortRule "inbound" ${recipesPort} ${recipesAddr} "tcp"

    addIPToZone "containers" ${recipesAddr}
}


main
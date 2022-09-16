#!/bin/bash

set -e


function includeDependencies() {
    source "${currentDir}/_setup-network.sh"
}

libDir=_libDir_
includeDependencies


function main() {
    read -rp "Enter the zone to add to: " zone
    if [ -z "${zone}" ]; then
        zone="trusted"
    fi

    read -rp "Enter the IP address to allowed list: " ipAddr
    if [ -z "${ipAddr}" ]; then
        echo "nothing done"
    else 
        addIPToZone ${zone} ${ipaddr}
    fi
}


main
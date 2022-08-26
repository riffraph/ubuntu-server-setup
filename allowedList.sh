#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${currentDir}/_setup-network.sh"
}

currentDir=$(getCurrentDir)
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
        addIPToWhitelist ${zone} ${ipaddr}
    fi
}


main
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

function main() {
    echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


    if grep -q "plexPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE}; then
        plexPort=$(grep "plexPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE} | sed 's/.*=//')
    else
        plexPort=32400
    fi
    
    if grep -q "sonarrPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE}; then
        sonarrPort=$(grep "sonarrPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE} | sed 's/.*=//')
    else
        sonarrPort=8989
    fi

    if grep -q "radarrPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE}; then
        radarrPort=$(grep "radarrPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE} | sed 's/.*=//')
    else
        radarrPort=7878
    fi

    if grep -q "nzbgetPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE}; then
        nzbgetPort=$(grep "nzbgetPort=" ${SCRIPT_FOLDER}/${CONFIG_FILE} | sed 's/.*=//')
    else
        nzbgetPort=6789
    fi

    # get IP addresses for each respective container
    plexAddr=$(getContainerIPAddress "plex")
    sonarrAddr=$(getContainerIPAddress "sonarr")
    radarrAddr=$(getContainerIPAddress "radarr")
    nzbgetAddr=$(getContainerIPAddress "nzbget")

    resetForwardPortRule "inbound" ${plexPort} ${plexAddr} "tcp"
    resetForwardPortRule "inbound" ${plexPort} ${plexAddr} "udp"
    resetForwardPortRule "restrInbound" ${sonarrPort} ${sonarrAddr} "tcp"
    resetForwardPortRule "restrInbound" ${radarrPort} ${radarrAddr} "tcp"
    resetForwardPortRule "restrInbound" ${nzbgetPort} ${nzbgetAddr} "tcp"

    # TODO: remove all sources from container zone

    addIPToZone "containers" ${plexAddr}
    addIPToZone "containers" ${sonarrAddr}
    addIPToZone "containers" ${radarrAddr}
    addIPToZone "containers" ${nzbgetAddr}


    echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."
}


main
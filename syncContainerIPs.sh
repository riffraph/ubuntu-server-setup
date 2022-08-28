#!/bin/bash

# this script is intended to be used when the container ip address changes

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
    read -rp "Enter the port to access Plex (default is 32400): " plexPort
    if [ -z "${plexPort}" ]; then
        plexPort=32400
    fi

    read -rp "Enter the port to access Sonarr (default is 8989): " sonarrPort
    if [ -z "${sonarrPort}" ]; then
        sonarrPort=8989
    fi

    read -rp "Enter the port to access Radarr (default is 7878): " radarrPort
    if [ -z "${radarrPort}" ]; then
        radarrPort=7878
    fi

    read -rp "Enter the port to access Nzbget (default is 6789): " nzbgetPort
    if [ -z "${nzbgetPort}" ]; then
        nzbgetPort=6789
    fi

    # get IP addresses for each respective container
    plexAddr=$(getContainerIPAddress "plex")
    sonarrAddr=$(getContainerIPAddress "sonarr")
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
}


main
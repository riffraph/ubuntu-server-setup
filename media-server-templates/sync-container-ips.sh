#!/bin/bash

# this script is intended to be used when the container ip address changes

set -e

function includeDependencies() {
    source "${libDir}/_setup-network.sh"
}

libDir=_libDir_
includeDependencies


function main() {
    plexPort=32400
    sonarrPort=8989
    radarrPort=7878
    nzbgetPort=6789

    # read -rp "Enter the port to access Plex (default is 32400): " plexPort
    # if [ -z "${plexPort}" ]; then
    # fi

    # read -rp "Enter the port to access Sonarr (default is 8989): " sonarrPort
    # if [ -z "${sonarrPort}" ]; then
    # fi

    # read -rp "Enter the port to access Radarr (default is 7878): " radarrPort
    # if [ -z "${radarrPort}" ]; then
    # fi

    # read -rp "Enter the port to access Nzbget (default is 6789): " nzbgetPort
    # if [ -z "${nzbgetPort}" ]; then
    # fi

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
}


main
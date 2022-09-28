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


function main() {
    if grep -q "plexPort=" ${scriptDir}/${configFile}; then
        plexPort=$(grep "plexPort=" ${scriptDir}/${configFile} | sed 's/.*=//')
    else
        plexPort=32400
    fi
    
    if grep -q "sonarrPort=" ${scriptDir}/${configFile}; then
        sonarrPort=$(grep "sonarrPort=" ${scriptDir}/${configFile} | sed 's/.*=//')
    else
        sonarrPort=8989
    fi

    if grep -q "radarrPort=" ${scriptDir}/${configFile}; then
        radarrPort=$(grep "radarrPort=" ${scriptDir}/${configFile} | sed 's/.*=//')
    else
        radarrPort=7878
    fi

    if grep -q "nzbgetPort=" ${scriptDir}/${configFile}; then
        nzbgetPort=$(grep "nzbgetPort=" ${scriptDir}/${configFile} | sed 's/.*=//')
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
}


main
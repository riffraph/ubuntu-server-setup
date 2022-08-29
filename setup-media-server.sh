#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${currentDir}/_setup-mounts.sh"
    source "${currentDir}/_setup-network.sh"
    source "${currentDir}/_utils.sh"
}

currentDir=$(getCurrentDir)
includeDependencies
logFile=$(basename $0) 
logFile+=".log"
outputScriptDir="/usr/scripts"


function main() {
    # Run setup functions
    trap EXIT SIGHUP SIGINT SIGTERM

    # create fd 3, redirect stdout and stderr to the log 
    exec 3>&1 2>&1 1>>${logFile}

    resetLog ${logFile}
    logTimestamp ${logFile}


    printAndLog "Create users, groups and directory structure..."
    mediaGroup="media"
    downloaderGroup="downloader"
    plexUsername="plex"
    sonarrUsername="sonarr"
    radarrUsername="radarr"
    nzbgetUsername="nzbget"
    createUsersAndDirectoryStructure ${mediaGroup} ${downloaderGroup} ${plexUsername} ${sonarrUsername} ${radarrUsername} ${nzbgetUsername}


    printAndLog "Configuring docker network..."
    createDockerNetwork ${mediaGroup}
    createDockerNetwork ${downloaderGroup}


    printAndLog "Configuring mounting point for Google Drive..."
    installMergerfs
    installRClone
    if [[ ! -e ${outputScriptDir} ]];
    then
        mkdir -p ${outputScriptDir}
    fi
    mountDrive ${outputScriptDir}

    # TODO: reconcile the mount points and the mapping for each app in docker
    

    printAndLog "Install and run media server apps..."

    read -rp "Enter your Plex claim: " plexClaim

    plexUID=$(id -u ${plexUsername})
    plexGID=$(getent group ${mediaGroup} | cut -d: -f3)
    sonarrUID=$(id -u ${sonarrUsername})
    sonarrGID=$(getent group ${downloaderGroup} | cut -d: -f3)
    radarrUID=$(id -u ${radarrUsername})
    radarrGID=$(getent group ${downloaderGroup} | cut -d: -f3)
    nzbgetUID=$(id -u ${nzbgetUsername})
    nzbgetGID=$(getent group ${downloaderGroup} | cut -d: -f3)
    timezone=$(getTimezone)

    mediaComposeFile="media-docker-compose.yaml"
    prepComposeFile ${mediaComposeFile} ${mediaGroup} ${timezone} ${plexUID} ${plexGID} ${plexClaim} ${downloaderGroup} ${sonarrUID} ${sonarrGID} ${radarrUID} ${radarrGID} ${nzbgetUID} ${nzbgetGID}
    
    docker compose -f ${mediaComposeFile} up -d


    printAndLog "Configure port forwarding for media server apps..."

    read -rp "Enter the IP address to allow access to restricted apps from: " restrictedIPAddr
    if [ -z "${plexPort}" ]; then
        addIPToZone "trusted" ${restrictedIPAddr}
    fi

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
    radarrAddr=$(getContainerIPAddress "radarr")
    nzbgetAddr=$(getContainerIPAddress "nzbget")

    resetForwardPortRule "inbound" ${plexPort} ${plexAddr} "tcp"
    resetForwardPortRule "inbound" ${plexPort} ${plexAddr} "udp"
    resetForwardPortRule "restrInbound" ${sonarrPort} ${sonarrAddr} "tcp"
    resetForwardPortRule "restrInbound" ${radarrPort} ${radarrAddr} "tcp"
    resetForwardPortRule "restrInbound" ${nzbgetPort} ${nzbgetAddr} "tcp"

    addIPToZone "containers" ${plexAddr}
    addIPToZone "containers" ${sonarrAddr}
    addIPToZone "containers" ${radarrAddr}
    addIPToZone "containers" ${nzbgetAddr}


    printAndLog "Preparing maintenance scripts..."
    if [[ ! -e ${outputScriptDir} ]];
    then
        mkdir -p ${outputScriptDir}
    fi
    prepMaintenanceScripts ${outputScriptDir}
    printAndLog "Maintenance scripts are available in ${outputScriptDir}"


    printAndLog "Setup Done! Log file is located at ${logFile}"
}


function createUsersAndDirectoryStructure() {
    local mediaGroup=${1}
    local downloaderGroup=${2}
    local plexUsername=${3}
    local sonarrUsername=${4}
    local radarrUsername=${5}
    local nzbgetUsername=${6}

    # create groups
    groupadd -f ${downloaderGroup}
    groupadd -f ${mediaGroup}

    # create users
    useradd -U ${nzbgetUsername} -G ${downloaderGroup}
    useradd -U ${sonarrUsername} -G ${downloaderGroup}
    useradd -U ${radarrUsername} -G ${downloaderGroup}
    usermod -a -G ${mediaGroup} ${sonarrUsername}
    usermod -a -G ${mediaGroup} ${radarrUsername}
    useradd -U ${plexUsername} -G ${mediaGroup}
    
    # create folders
    mkdir /downloads
    mkdir -p /dvr/movies
    mkdir -p /dvr/tv
    mkdir -p /serverapps/nzbget/config
    mkdir -p /serverapps/sonarr/config
    mkdir -p /serverapps/radarr/config
    mkdir -p /serverapps/plex/config
    mkdir -p /serverapps/plex/transcode

    # set up owners
    chown -R ${plexUsername}.${mediaGroup} /dvr
    chown -R ${nzbgetUsername}.${downloaderGroup} /downloads
    chown -R ${nzbgetUsername}.${nzbgetUsername} /serverapps/nzbget
    chown -R ${sonarrUsername}.${sonarrUsername} /serverapps/sonarr
    chown -R ${radarrUsername}.${radarrUsername} /serverapps/radarr
    chown -R ${plexUsername}.${plexUsername} /serverapps/plex


    scheduleUpdateOfPermissions ${plexUsername} ${mediaGroup}
}


function scheduleUpdateOfPermissions() {
    local plexUsername=${1}
    local plexGroup=${2}

    # finds files which are not 664 permission and fixes them
    (crontab -l 2>/dev/null; echo "*/15 * * * * find /dvr -type f \! -perm 664 -exec chmod 664 {} \;") | crontab -u ${plexUsername} -

    # finds directories which are not 777 and fixes them
    (crontab -l 2>/dev/null; echo "*/15 * * * * find /dvr -type d \! -perm 775 -exec chmod 775 {} \;") | crontab -u ${plexUsername} -

    # finds anything not owned by plex and fixes them
    (crontab -l 2>/dev/null; echo "*/15 * * * * find /dvr \! -user ${plexUsername} -exec chown ${plexUsername}.${plexGroup} {} \;") | crontab -u ${plexUsername} -
}


function prepComposeFile() {
    local composeFile=${1}
    local mediaNetwork=${2}
    local timezone=${3} 
    local plexUID=${4} 
    local plexGID=${5} 
    local plexClaim=${6}
    local downloaderNetwork=${7}
    local sonarrUID=${8}  
    local sonarrGID=${9}  
    local radarrUID=${10}  
    local radarrGID=${11}  
    local nzbgetUID=${12}  
    local nzbgetGID=${13}   

    sed -re "s~_timezone_~${timezone}~g" -i ${composeFile}
    sed -re "s/_medianetwork_/${mediaNetwork}/g" -i ${composeFile}
    sed -re "s/_plexuid_/${plexUID}/g" -i ${composeFile}
    sed -re "s/_plexgid_/${plexGID}/g" -i ${composeFile}
    sed -re "s/_plexclaim_/${plexClaim}/g" -i ${composeFile}
    sed -re "s/_downloadernetwork_/${downloaderNetwork}/g" -i ${composeFile}
    sed -re "s/_sonarruid_/${sonarrUID}/g" -i ${composeFile}
    sed -re "s/_sonarrgid_/${sonarrGID}/g" -i ${composeFile}
    sed -re "s/_radarruid_/${radarrUID}/g" -i ${composeFile}
    sed -re "s/_radarrgid_/${radarrGID}/g" -i ${composeFile}
    sed -re "s/_nzbgetuid_/${nzbgetUID}/g" -i ${composeFile}
    sed -re "s/_nzbgetgid_/${nzbgetGID}/g" -i ${composeFile}
}


main
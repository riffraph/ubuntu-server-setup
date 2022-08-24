#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${currentDir}/_setup-network.sh"
    source "${currentDir}/_utils.sh"
}

currentDir=$(getCurrentDir)
includeDependencies
logFile=$(basename $0) 
logFile+=".log"


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
    nzbgetUsername="nzbget"
    createUsersAndDirectoryStructure ${mediaGroup} ${downloaderGroup} ${plexUsername} ${sonarrUsername} ${nzbgetUsername}


    printAndLog "Configuring docker network..."
    createDockerNetwork ${mediaGroup}
    createDockerNetwork ${downloaderGroup}


    printAndLog "Installing rclone... TODO"
    

    printAndLog "Install and run media server apps..."

    read -rp "Enter your Plex claim: " plexClaim

    plexUID=$(id -u ${plexUsername})
    plexGID=$(getent group ${mediaGroup} | cut -d: -f3)
    sonarrUID=$(id -u ${sonarrUsername})
    sonarrGID=$(getent group ${downloaderGroup} | cut -d: -f3)
    nzbgetUID=$(id -u ${nzbgetUsername})
    nzbgetGID=$(getent group ${downloaderGroup} | cut -d: -f3)
    timezone=$(getTimezone)

    mediaComposeFile="media-docker-compose.yaml"
    prepComposeFile ${mediaComposeFile} ${mediaGroup} ${timezone} ${plexUID} ${plexGID} ${plexClaim} ${downloaderGroup} ${sonarrUID} ${sonarrGID} ${nzbgetUID} ${nzbgetGID}
    
    docker compose -f ${mediaComposeFile} up -d


    printAndLog "Configure port forwarding for media server apps..."

    read -rp "Enter the port to access Plex (default is 32400): " plexPort
    if [ -z "${plexPort}" ]; then
        plexPort=32400
    fi

    read -rp "Enter the port to access Sonarr (default is 8989): " sonarrPort
    if [ -z "${sonarrPort}" ]; then
        sonarrPort=8989
    fi

    read -rp "Enter the port to access Nzbget (default is 6789): " nzbgetPort
    if [ -z "${nzbgetPort}" ]; then
        nzbgetPort=6789
    fi

    # get IP addresses for each respective container
    plexAddr=$(getContainerIPAddress "plex")
    sonarrAddr=$(getContainerIPAddress "sonarr")
    nzbgetAddr=$(getContainerIPAddress "nzbget")
    containerPolicy="worldToContainers"

    resetForwardPortRules ${containerPolicy} ${plexPort} ${plexAddr} ${sonarrPort} ${sonarrAddr} ${nzbgetPort} ${nzbgetAddr}


    printAndLog "Setup Done! Log file is located at ${logFile}"
}


function createUsersAndDirectoryStructure() {
    local mediaGroup=${1}
    local downloaderGroup=${2}
    local plexUsername=${3}
    local sonarrUsername=${4}
    local nzbgetUsername=${5}

    # create groups
    groupadd -f ${downloaderGroup}
    groupadd -f ${mediaGroup}

    # create users
    useradd -U ${nzbgetUsername} -G ${downloaderGroup}
    useradd -U ${sonarrUsername} -G ${downloaderGroup}
    usermod -a -G ${mediaGroup} ${sonarrUsername}
    useradd -U ${plexUsername} -G ${mediaGroup}
    
    # create folders
    mkdir /downloads
    mkdir -p /dvr/movies
    mkdir -p /dvr/tv
    mkdir -p /serverapps/nzbget/config
    mkdir -p /serverapps/sonarr/config
    mkdir -p /serverapps/plex/config
    mkdir -p /serverapps/plex/transcode

    # set up owners
    chown -R ${plexUsername}.${mediaGroup} /dvr
    chown -R ${nzbgetUsername}.${downloaderGroup} /downloads
    chown -R ${nzbgetUsername}.${nzbgetUsername} /serverapps/nzbget
    chown -R ${sonarrUsername}.${sonarrUsername} /serverapps/sonarr
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
    local nzbgetUID=${10}  
    local nzbgetGID=${11}   

    sed -re "s~_timezone_~${timezone}~g" -i ${composeFile}
    sed -re "s/_medianetwork_/${mediaNetwork}/g" -i ${composeFile}
    sed -re "s/_plexuid_/${plexUID}/g" -i ${composeFile}
    sed -re "s/_plexgid_/${plexGID}/g" -i ${composeFile}
    sed -re "s/_plexclaim_/${plexClaim}/g" -i ${composeFile}
    sed -re "s/_downloadernetwork_/${downloaderNetwork}/g" -i ${composeFile}
    sed -re "s/_sonarruid_/${sonarrUID}/g" -i ${composeFile}
    sed -re "s/_sonarrgid_/${sonarrGID}/g" -i ${composeFile}
    sed -re "s/_nzbgetuid_/${nzbgetUID}/g" -i ${composeFile}
    sed -re "s/_nzbgetgid_/${nzbgetGID}/g" -i ${composeFile}
}


main
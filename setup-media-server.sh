#!/bin/bash

# create network for the media server
function createDockerNetwork() {
    local mediaNetwork=${1}
    local downloaderNetwork=${2}

    docker network create --driver bridge ${mediaNetwork}
    docker network create --driver bridge ${downloaderNetwork}
}

function createUsersAndDirectoryStructure() {
    local mediaGroup=${1}
    local downloaderGroup=${2}
    local plexUsername=${3}
    local sonarrUsername=${4}
    local nzbgetUsername=${5}

    # create groups
    groupadd -g 1002 ${downloaderGroup}
    groupadd -g 1003 ${mediaGroup}

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

function prepCompose() {
    local composeFile=${1}
    local mediaNetwork=${2}
    local downloaderNetwork=${3}
    local timezone=${4} 
    local plexUID=${5} 
    local plexGID=${6} 
    local plexClaim=${7}  
    local sonarrUID=${8}  
    local sonarrGID=${9}  
    local nzbgetUID=${10}  
    local nzbgetGID=${11} 

    sed -re "s/_timezone_/${timezone}/g" -i ${composeFile}
    sed -re "s/_medianetwork_/${mediaNetwork}/g" -i ${composeFile}
    sed -re "s/_downloadernetwork_/${downloaderNetwork}/g" -i ${composeFile}
    sed -re "s/_plexuid_/${plexUID}/g" -i ${composeFile}
    sed -re "s/_plexgid_/${plexGID}/g" -i ${composeFile}
    sed -re "s/_plexclaim_/${plexClaim}/g" -i ${composeFile}
    sed -re "s/_sonarruid_/${sonarrUID}/g" -i ${composeFile}
    sed -re "s/_sonarrgid_/${sonarrGID}/g" -i ${composeFile}
    sed -re "s/_nzbgetuid_/${nzbgetUID}/g" -i ${composeFile}
    sed -re "s/_nzbgetgid_/${nzbgetGID}/g" -i ${composeFile}
}
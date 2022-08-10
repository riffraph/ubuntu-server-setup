#!/bin/bash

# create network for the media server
function createDockerNetwork() {
    local externalNetworkInterface=${1}

    docker network create \
    -d macvlan \
    --subnet=192.168.86.0/24 \
    --gateway=192.168.86.1 \
    --ip-range=192.168.86.30/30 \
    -o parent=${externalNetworkInterface} \
    media-network
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


    printAndLog "Configuring directory structure..."
    
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

    crontab -l > _tmp_crontab

    # finds files which are not 664 permission and fixes them
    echo "find /dvr -type f \! -perm 664 -exec chmod 664 {} \;" >> _tmp_crontab

    # finds directories which are not 777 and fixes them
    echo "find /dvr -type d \! -perm 775 -exec chmod 775 {} \;" >> _tmp_crontab

    # finds anything not owned by plex and fixes them
    echo "find /dvr \! -user ${plexUsername} -exec chown ${plexUsername}.${plexGroup} {} \;" >> _tmp_crontab

    crontab _tmp_crontab
    rm _tmp_crontab
}

function prepCompose() {
    local composeFile=${1}
    local timezone=${2} 
    local plexUID=${3} 
    local plexGID=${4} 
    local plexClaim=${5}  
    local sonarrUID=${6}  
    local sonarrGID=${7}  
    local nzbgetUID=${8}  
    local nzbgetGID=${9} 

    sed -re "s/_timezone_/${timezone}/g" -i ${composeFile}
    sed -re "s/_plexuid_/${plexUID}/g" -i ${composeFile}
    sed -re "s/_plexgid_/${plexGID}/g" -i ${composeFile}
    sed -re "s/_plexclaim_/${plexClaim}/g" -i ${composeFile}
    sed -re "s/_sonarruid_/${sonarrUID}/g" -i ${composeFile}
    sed -re "s/_sonarrgid_/${sonarrGID}/g" -i ${composeFile}
    sed -re "s/_nzbgetuid_/${nzbgetUID}/g" -i ${composeFile}
    sed -re "s/_nzbgetgid_/${nzbgetGID}/g" -i ${composeFile}
}
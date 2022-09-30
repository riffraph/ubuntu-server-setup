#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${CURRENT_FOLDER}/_setup-data.sh"
    source "${CURRENT_FOLDER}/_setup-network.sh"
    source "${CURRENT_FOLDER}/_utils.sh"
    source "${CURRENT_FOLDER}/_media-scripts.sh"
}

CURRENT_FOLDER=$(getCurrentDir)
TEMPLATES_FOLDER="media-server-templates"
OUTPUT_FOLDER="/usr/mediaserver"
CONFIG_FOLDER="config"

DATA_ROOT_FOLDER="/mnt/user"
MERGED_FOLDER="${dataRootFolder}/merged"


includeDependencies

function main() {
    echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


    if [[ ! -e ${OUTPUT_FOLDER} ]];
    then
        mkdir -p ${OUTPUT_FOLDER}
    fi

    ./generate-media-scripts.sh ${OUTPUT_FOLDER}


    echo "$(date "+%d.%m.%Y %T") INFO: Create users, groups and folder structure."
    mediaGroup="media"
    downloaderGroup="downloader"
    plexUsername="plex"
    sonarrUsername="sonarr"
    radarrUsername="radarr"
    nzbgetUsername="nzbget"
    createUsersAndDirectoryStructure ${mediaGroup} ${downloaderGroup} ${plexUsername} ${sonarrUsername} ${radarrUsername} ${nzbgetUsername} ${OUTPUT_FOLDER} ${MERGED_FOLDER}
    ${OUTPUT_FOLDER}/set-permissions.sh

    echo "$(date "+%d.%m.%Y %T") INFO: Configuring docker network."
    createDockerNetwork ${mediaGroup}
    createDockerNetwork ${downloaderGroup}


    echo "$(date "+%d.%m.%Y %T") INFO: Install media server apps."

    read -rp "Enter your Plex claim: " plexClaim

    plexUID=$(id -u ${plexUsername})
    plexGID=$(getent group ${mediaGroup} | cut -d: -f3)
    sonarrUID=$(id -u ${sonarrUsername})
    sonarrGID=$(getent group ${mediaGroup} | cut -d: -f3)
    radarrUID=$(id -u ${radarrUsername})
    radarrGID=$(getent group ${mediaGroup} | cut -d: -f3)
    nzbgetUID=$(id -u ${nzbgetUsername})
    nzbgetGID=$(getent group ${mediaGroup} | cut -d: -f3)
    timezone=$(getTimezone)

    mediaComposeFile="media-docker-compose.yaml"
    cp ${TEMPLATES_FOLDER}/${mediaComposeFile} ${OUTPUT_FOLDER}/
    prepComposeFile "${OUTPUT_FOLDER}/${mediaComposeFile}" ${mediaGroup} ${timezone} ${plexUID} ${plexGID} ${plexClaim} ${downloaderGroup} ${sonarrUID} ${sonarrGID} ${radarrUID} ${radarrGID} ${nzbgetUID} ${nzbgetGID} ${MERGED_FOLDER}
    echo "$(date "+%d.%m.%Y %T") INFO: Docker compose file is available in ${OUTPUT_FOLDER}"

    echo "$(date "+%d.%m.%Y %T") INFO: Note that the applications will be started in the background."
    (crontab -l 2>/dev/null; echo "*/10 * * * * ${OUTPUT_FOLDER}/run-apps.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "*/30 * * * * ${OUTPUT_FOLDER}/set-permissions.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "0 3 * * * truncate -s 0 ${MERGED_FOLDER}/downloads/nzbget.log") | crontab -u root -


    echo "$(date "+%d.%m.%Y %T") INFO: Configure port forwarding for media server apps."

    read -rp "Enter the IP address to allow access to restricted apps from: " restrictedIPAddr
    if [ -z "${plexPort}" ]; then
        addIPToZone "trusted" ${restrictedIPAddr}
    fi

    read -rp "Enter the port to access Plex (default is 32400): " plexPort
    if [ -z "${plexPort}" ]; then
        plexPort=32400
    fi

    echo "plexPort=${plexPort}" > ${OUTPUT_FOLDER}/${CONFIG_FOLDER}

    read -rp "Enter the port to access Sonarr (default is 8989): " sonarrPort
    if [ -z "${sonarrPort}" ]; then
        sonarrPort=8989
    fi

    echo "sonarrPort=${sonarrPort}" >> ${OUTPUT_FOLDER}/${CONFIG_FOLDER}

    read -rp "Enter the port to access Radarr (default is 7878): " radarrPort
    if [ -z "${radarrPort}" ]; then
        radarrPort=7878
    fi

    echo "radarrPort=${radarrPort}" >> ${OUTPUT_FOLDER}/${CONFIG_FOLDER}

    read -rp "Enter the port to access Nzbget (default is 6789): " nzbgetPort
    if [ -z "${nzbgetPort}" ]; then
        nzbgetPort=6789
    fi

    echo "nzbgetPort=${nzbgetPort}" >> ${OUTPUT_FOLDER}/${CONFIG_FOLDER}

    ${OUTPUT_FOLDER}/sync-container-ips.sh 


    echo "$(date "+%d.%m.%Y %T") INFO: Maintenance scripts are available in ${OUTPUT_FOLDER}"


    echo "$(date "+%d.%m.%Y %T") INFO: Script complete"
}


function createUsersAndDirectoryStructure() {
    local mediaGroup=${1}
    local downloaderGroup=${2}
    local plexUsername=${3}
    local sonarrUsername=${4}
    local radarrUsername=${5}
    local nzbgetUsername=${6}
    local configFolder=${7}
    local dataFolder=${8}

    # create groups
    groupadd -f ${mediaGroup}

    # create users
    useradd -U ${nzbgetUsername} -G ${downloaderGroup}
    useradd -U ${sonarrUsername} -G ${downloaderGroup}
    useradd -U ${radarrUsername} -G ${downloaderGroup}
    usermod -a -G ${mediaGroup} ${sonarrUsername}
    usermod -a -G ${mediaGroup} ${radarrUsername}
    usermod -a -G ${mediaGroup} ${nzbgetUsername}
    useradd -U ${plexUsername} -G ${mediaGroup}
    
    # create folders for the apps
    mkdir -p ${configFolder}/nzbget/config
    mkdir -p ${configFolder}/sonarr/config
    mkdir -p ${configFolder}/radarr/config
    mkdir -p ${configFolder}/plex/config
    mkdir -p ${configFolder}/plex/transcode

    # create folders for the data
    mkdir -p ${dataFolder}/downloads/completed
    mkdir -p ${dataFolder}/movies
    mkdir -p ${dataFolder}/tv

    # set up owners
    chown -R ${nzbgetUsername}.${nzbgetUsername} ${configFolder}/nzbget
    chown -R ${sonarrUsername}.${sonarrUsername} ${configFolder}/sonarr
    chown -R ${radarrUsername}.${radarrUsername} ${configFolder}/radarr
    chown -R ${plexUsername}.${plexUsername} ${configFolder}/plex
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
    local dataFolder=${14}

    downloadsDirPath="${dataFolder}/downloads"
    downloadsCompleteDirPath="${dataFolder}/downloads/completed"
    moviesDirPath="${dataFolder}/movies"
    tvDirPath="${dataFolder}/tv"


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
    sed -re "s:_downloads_dir_:${downloadsDirPath}:g" -i ${composeFile}
    sed -re "s:_downloads_complete_:${downloadsCompleteDirPath}:g" -i ${composeFile}
    sed -re "s:_tv_:${tvDirPath}:g" -i ${composeFile}
    sed -re "s:_movies_:${moviesDirPath}:g" -i ${composeFile}
}


main
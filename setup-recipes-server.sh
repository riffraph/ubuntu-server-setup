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
templatesDir="recipes-server-templates"
outputDir="/usr/recipesserver"


function main() {
    if [[ ! -e ${outputDir} ]];
    then
        mkdir -p ${outputDir}
    fi

    cp ${templatesDir}/* ${outputDir}
    cp ${templatesDir}/.env ${outputDir}/

    echo "Create users, groups and directory structure..."
    recipesGroup="recipes"
    recipesUsername="recipesUser"
    createUsersAndDirectoryStructure ${recipesGroup} ${recipesUsername}


    echo "Configuring docker network..."
    createDockerNetwork ${recipesGroup}


    echo "Install and run recipes server apps..."

    read -rp "Enter the secret key for Tandoor Recipes: " secretKey
    read -rp "Enter the password for the Tandoor Recipes Postgres instance: " postgresPwd

    timezone=$(getTimezone)
    envSettingsFile=".env"
    prepEnvironmentSettingsFile "${outputDir}/${envSettingsFile}" ${timezone} ${secretKey} ${postgresPwd}

    postgresqlDir="/usr/recipesserver/postgresql/"
    mediafilesDir="/usr/recipesserver/mediafiles/"

    recipesComposeFile="recipes-docker-compose.yaml"

    prepComposeFile "${outputDir}/${recipesComposeFile}" ${recipesGroup} ${postgresqlDir} ${mediafilesDir}
    echo "Docker compose file is available in ${outputDir}"


    docker compose -f "${outputDir}/${recipesComposeFile}" up -d


    echo "Configure port forwarding for recipe apps..."

    read -rp "Enter the port to access Tandoor Recipes (default is 100): " recipesPort
    if [ -z "${recipesPort}" ]; then
        recipesPort=100
    fi

    syncContainerIps recipesPort 80

    echo "Preparing maintenance scripts..."
    prepMaintenanceScripts ${outputDir} $PWD
    echo "Maintenance scripts are available in ${outputDir}"

 
    (crontab -l 2>/dev/null; echo "*/15 * * * * ${outputDir}/sync-container-ips.sh") | crontab -u root -
}


function createUsersAndDirectoryStructure() {
    local recipesGroup=${1}
    local recipesUsername=${2}

    # create groups
    groupadd -f ${recipesGroup}

    # create users
    useradd -U ${recipesUsername} -G ${recipesGroup}
    
    # create folders
    mkdir -p /usr/recipesserver/postgresql
    mkdir -p /usr/recipesserver/mediafiles

    # set up owners
    chown -R ${recipesUsername}.${recipesGroup} /usr/recipesserver/

    chmod g+s /usr/recipesserver/
	setfacl -d -R -m g::rwx /usr/recipesserver/
}


function prepComposeFile() {
    local composeFile=${1}
    local recipesNetwork=${2}
    local postgresqlDir=${3}
    local mediafilesDir=${4}
    
    sed -re "s:_postgresql_:${postgresqlDir}:g" -i ${composeFile}
    sed -re "s:_media_files_:${mediafilesDir}:g" -i ${composeFile}
    sed -re "s/_recipesnetwork_/${recipesNetwork}/g" -i ${composeFile}
}


function prepEnvironmentSettingsFile() {
    local envSettingsFile=${1}
    local timezone=${2}
    local secretKey=${3}
    local postgresPwd=${4}
    
    sed -re "s:_timezone_:${timezone}:g" -i ${envSettingsFile}
    sed -re "s:_secret_key_:${secretKey}:g" -i ${envSettingsFile}
    sed -re "s:_postgres_pwd_:${postgresPwd}:g" -i ${envSettingsFile}
}

function syncContainerIps() {
    local externalPort=${1}
    local internalPort=${2}

    recipesProxyAddr=$(getContainerIPAddress "recipes-proxy")
    recipesWebAddr=$(getContainerIPAddress "recipes-web")
    recipesDBAddr=$(getContainerIPAddress "recipes-db")

    resetForwardPortRule "inbound" ${externalPort} ${recipesProxyAddr} "tcp" ${internalPort}

    addIPToZone "containers" ${recipesProxyAddr}
    addIPToZone "containers" ${recipesWebAddr}
    addIPToZone "containers" ${recipesDBAddr}
}


main
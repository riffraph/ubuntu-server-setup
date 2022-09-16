#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${currentDir}/_setup-data.sh"
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

    echo "Create users, groups and directory structure..."
    recipesGroup="recipes"
    recipesUsername="recipes"
    createUsersAndDirectoryStructure ${recipesGroup} ${recipesUsername}


    echo "Configuring docker network..."
    createDockerNetwork ${recipesGroup}


    echo "Install and run recipes server apps..."

    postgresqlDir="/usr/recipesserver/postgresql/"
    mediafilesDir="/usr/recipesserver/mediafiles/"

    recipesComposeFile="recipes-docker-compose.yaml"

    prepComposeFile "${outputDir}/${recipesComposeFile}" ${recipesNetwork} ${postgresqlDir} ${mediafilesDir}
    echo "Docker compose file is available in ${outputDir}"


    docker compose -f "${outputDir}/${mediaComposeFile}" up -d


    echo "Configure port forwarding for recipe apps..."

    read -rp "Enter the port to access Tandoor Recipes (default is 100): " recipesPort
    if [ -z "${recipesPort}" ]; then
        recipesPort=100
    fi

    # get IP addresses for each respective container
    recipesAddr=$(getContainerIPAddress "recipes-nginx")

    resetForwardPortRule "inbound" ${recipesPort} ${recipesAddr} "tcp"

    addIPToZone "containers" ${recipesAddr}


    echo "Preparing maintenance scripts..."
    prepMaintenanceScripts ${outputDir} $PWD
    echo "Maintenance scripts are available in ${outputDir}"
}


function createUsersAndDirectoryStructure() {
    local recipesGroup=${1}
    local recipesUsername=${3}

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
    local mediafilesDir=${3}
    
    sed -re "s:_postgresql_:${postgresqlDir}:g" -i ${composeFile}
    sed -re "s:_mediafiles_:${mediafilesDir}:g" -i ${composeFile}
    sed -re "s/_recipesnetwork_/${recipesNetwork}/g" -i ${composeFile}
}


main
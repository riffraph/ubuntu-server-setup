#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${CURRENT_FOLDER}/_setup-network.sh"
    source "${CURRENT_FOLDER}/_utils.sh"
    source "${CURRENT_FOLDER}/_recipes-scripts.sh"
}

CURRENT_FOLDER=$(getCurrentDir)
TEMPLATES_FOLDER="recipes-server-templates"
OUTPUT_FOLDER="/usr/recipesserver"
CONFIG_FILE="config"


includeDependencies

function main() {
    echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


    if [[ ! -e ${OUTPUT_FOLDER} ]];
    then
        mkdir -p ${OUTPUT_FOLDER}
    fi

    ./generate-recipes-scripts.sh ${OUTPUT_FOLDER}


    echo "$(date "+%d.%m.%Y %T") INFO: Create users, groups and directory structure."
    recipesGroup="recipes"
    recipesUsername="recipesUser"
    createUsersAndDirectoryStructure ${recipesGroup} ${recipesUsername} ${OUTPUT_FOLDER}


    echo "$(date "+%d.%m.%Y %T") INFO: Configuring docker network."
    createDockerNetwork ${recipesGroup}


    echo "$(date "+%d.%m.%Y %T") INFO: Install and run recipes server apps."

    read -rp "Enter the secret key for Tandoor Recipes: " secretKey
    read -rp "Enter the password for the Tandoor Recipes Postgres instance: " postgresPwd

    timezone=$(getTimezone)
    envSettingsFile=".env"
    cp ${TEMPLATES_FOLDER}/${envSettingsFile} ${OUTPUT_FOLDER}/
    prepEnvironmentSettingsFile "${OUTPUT_FOLDER}/${envSettingsFile}" ${timezone} ${secretKey} ${postgresPwd}

    postgresqlDir="/usr/recipesserver/postgresql/"
    mediafilesDir="/usr/recipesserver/mediafiles/"

    recipesComposeFile="recipes-docker-compose.yaml"
    cp ${TEMPLATES_FOLDER}/${recipesComposeFile} ${OUTPUT_FOLDER}/
    prepComposeFile "${OUTPUT_FOLDER}/${recipesComposeFile}" ${recipesGroup} ${postgresqlDir} ${mediafilesDir}
    echo "$(date "+%d.%m.%Y %T") INFO: Docker compose file is available in ${OUTPUT_FOLDER}"

    docker compose -f "${OUTPUT_FOLDER}/${recipesComposeFile}" up -d

    (crontab -l 2>/dev/null; echo "30 23 * * * ${OUTPUT_FOLDER}/backup.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "0 5 * * 2 ${OUTPUT_FOLDER}/update-apps.sh") | crontab -u root -


    echo "$(date "+%d.%m.%Y %T") INFO: Configure port forwarding for recipe apps."

    read -rp "Enter the port to access Tandoor Recipes (default is 100): " recipesPort
    if [ -z "${recipesPort}" ]; then
        recipesPort=100
    fi

    echo "recipesPort=${recipesPort}" > ${OUTPUT_FOLDER}/${CONFIG_FILE}

    ${OUTPUT_FOLDER}/sync-container-ips.sh 
    (crontab -l 2>/dev/null; echo "*/30 * * * * ${OUTPUT_FOLDER}/sync-container-ips.sh") | crontab -u root -

    echo "$(date "+%d.%m.%Y %T") INFO: Maintenance scripts are available in ${OUTPUT_FOLDER}"


    echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."
}


function createUsersAndDirectoryStructure() {
    local recipesGroup=${1}
    local recipesUsername=${2}
    local configFolder=${3}

    # create groups
    groupadd -f ${recipesGroup}

    # create users
    useradd -U ${recipesUsername} -G ${recipesGroup}
    
    # create folders
    mkdir -p ${configFolder}/postgresql
    mkdir -p ${configFolder}/mediafiles

    # set up owners
    chown -R ${recipesUsername}.${recipesGroup} ${configFolder}
    chmod g+s ${configFolder}
	setfacl -d -R -m g::rwx ${configFolder}
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


main
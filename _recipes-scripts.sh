#!/bin/bash

# prepares sync-container-ips.sh
function prepSyncContainerIpsScript() {
    local destinationDir=${1}
    local libDir=${2}

    for file in ${destinationDir}/*.sh;
    do
        # update dependency from the script to this folder
        sed -re "s:_lib_folder_:${libDir}:g" -i ${file}
    done
}

# prepares backup.sh
function prepBackupScript() {
    local scriptPath=${1}
    local backupFolder=${2}
    local environmentFile=${3}

    sed -re "s:_backup_folder_:${backupFolder}:g" -i ${scriptPath}
    sed -re "s:_env_file_:${environmentFile}:g" -i ${scriptPath}
}

# prepare update-apps.sh
function prepUpdateAppsScript() {
    local scriptPath=${1}
    local dockerCompose=${2}
    local syncContainerIpsScript=${3}

    sed -re "s:_docker_compose_:${dockerCompose}:" -i ${scriptPath}
    sed -re "s:_sync_container_ips_script_:${syncContainerIpsScript}:" -i ${scriptPath}
}
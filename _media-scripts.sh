#!/bin/bash

function prepSyncContainerIpsScript() {
    local destinationDir=${1}
    local libDir=${2}

    for file in ${destinationDir}/*.sh;
    do
        # update dependency from the script to this folder
        sed -re "s:_lib_folder_:${libDir}:g" -i ${file}
    done
}

# prepare set-permissions.sh
function prepSetPermissionsScript() {
    local scriptPath=${1}
    local dataRootFolder=${2}

    localFolder="${dataRootFolder}/local"
    group="media"

    sed -re "s/_group_/${group}/" -i ${scriptPath}
    sed -re "s:_base_folder_:${localFolder}:" -i ${scriptPath}
}

# prepare run-apps.sh
function prepRunAppsScript() {
    local scriptPath=${1}
    local dataRootFolder=${2}
    local dockerCompose=${3}
    local syncContainerIpsScript=${4}

    mergedFolder="${dataRootFolder}/merged"

    sed -re "s:_merged_folder_:${mergedFolder}:" -i ${scriptPath}
    sed -re "s:_sync_container_ips_script_:${syncContainerIpsScript}:" -i ${scriptPath}
    sed -re "s:_docker_compose_:${dockerCompose}:" -i ${scriptPath}
}
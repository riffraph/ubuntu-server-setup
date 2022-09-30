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
#!/bin/bash

function prepMaintenanceScripts() {
    local destinationDir=${1}
    local libDir=${2}

    for file in ${destinationDir}/*.sh;
    do
        # update dependency from the script to this folder
        sed -re "s:_libDir_:${libDir}:g" -i ${file}
    done
}
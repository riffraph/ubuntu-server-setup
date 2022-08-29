#!/bin/bash


# Execute a command as a certain user
# Arguments:
#   Account Username
#   Command to be executed
function execAsUser() {
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H bash -c "${exec_command}"
}

# output styling
bold=$(tput bold)
underline=$(tput smul)
italic=$(tput sitm)
info=$(tput setaf 2)
error=$(tput setaf 160)
warn=$(tput setaf 214)
reset=$(tput sgr0)

function resetLog() {
    local filename=${1}

    printf '' > ${filename}
}


function logTimestamp() {
    local filename=${1}
    {
        echo "===================" 
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1
}


function printAndLog() {
    local string=${1}

    # print to the terminal and add to the log which is bound file descriptor 3
    echo ${1} | tee /dev/fd/3
}


# get timezone
function getTimezone() {
    local timezone=$(cat /etc/timezone)
    echo ${timezone}
}


function getContainerIPAddress() {
    local ipAddress=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${1})
    echo ${ipAddress}
}


function moveScript() {
    local file=${1} 
    local destinationDir=${2}

    # strip the prefix when moving
    newFilename=$(basename -- ${file})
    newFilename=${newFilename#_script_}
    mv ${file} ${destinationDir}/${newFilename}
}


function prepMaintenanceScripts() {
    local scriptDir=${1}
    local libDir=${2}

    tmpDir="tmp"

    if [[ ! -e ${tmpDir} ]]; 
    then
        mkdir -p ${tmpDir}
    fi

    cp _script_* ${tmpDir}

    for file in ./${tmpDir}/*.sh;
    do
        # update dependency from the script to this folder
        sed -re "s:_libDir_:${libDir}:g" -i ${file}

        moveScript ${file} ${scriptDir}
    done

    rm -rf ${tmpDir}
}
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

# prepares remove-old-backups.sh
function prepRemoveOldBackupScript() {
    local scriptPath=${1}
    local backupFolder=${2}
    local rcloneConfigPath=${3}

    rcloneRemoteName="gdrive-vfs"
    retentionPeriod=3

    sed -re "s:_backup_folder_:${backupFolder}:g" -i ${scriptPath}
    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s:_rclone_remote_:${rcloneRemoteName}:g" -i ${scriptPath}
    sed -re "s:_retention_period_:${retentionPeriod}:g" -i ${scriptPath}
}

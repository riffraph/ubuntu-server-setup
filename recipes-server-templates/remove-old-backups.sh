#!/bin/bash

# Script to remove old backups from the remote

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RETENTION_PERIOD=_retention_period_ # in days
DATE=$(date +%d-%m-%y -d "${RETENTION_PERIOD} days ago")
BACKUP_FOLDER="_backup_folder_/${DATE}"
RCLONE_CONFIG="_rclone_config_"
RCLONE_REMOTE_NAME="_rclone_remote_" # Name of rclone remote mount WITHOUT ':'.


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


echo "$(date "+%d.%m.%Y %T") INFO: Looking for backup from ${DATE} on remote."
if rclone lsd ${RCLONE_REMOTE_NAME}:${BACKUP_FOLDER} --config=${RCLONE_CONFIG} > /dev/null 2>&1 ;
then
    echo "$(date "+%d.%m.%Y %T") INFO: Removing backup from remote."
    rclone delete ${RCLONE_REMOTE_NAME}:${BACKUP_FOLDER} --config=${RCLONE_CONFIG}
fi


echo "$(date "+%d.%m.%Y %T") INFO: ${0} completed."

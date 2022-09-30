#!/bin/bash

# Script to back up the database and media files

# Depends on the environment file used by Tandoor recipes

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ENVIRONMENT_FILE="_env_file_"
DATE=$(date +%d-%m-%y)
BACKUP_FOLDER="_backup_folder_/${DATE}"


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


mkdir -p ${BACKUP_FOLDER}

postgresHost=$(grep "POSTGRES_HOST=" ${SCRIPT_FOLDER}/${ENVIRONMENT_FILE} | sed 's/.*=//')
postgresPort=$(grep "POSTGRES_PORT=" ${SCRIPT_FOLDER}/${ENVIRONMENT_FILE} | sed 's/.*=//')
postgresDB=$(grep "POSTGRES_DB=" ${SCRIPT_FOLDER}/${ENVIRONMENT_FILE} | sed 's/.*=//')
postgresUser=$(grep "POSTGRES_USER=" ${SCRIPT_FOLDER}/${ENVIRONMENT_FILE} | sed 's/.*=//')
postgresPassword=$(grep "POSTGRES_PASSWORD=" ${SCRIPT_FOLDER}/${ENVIRONMENT_FILE} | sed 's/.*=//')

echo "$(date "+%d.%m.%Y %T") INFO: Backing up database to ${BACKUP_FOLDER}."
PGPASSWORD=${postgresPassword} pg_dump --inserts --column-inserts --username=${postgresUser}--host=${postgresHost} --port=${postgresPort} ${postgresDB} > ${BACKUP_FOLDER}/dbbackup.sql


echo "$(date "+%d.%m.%Y %T") INFO: ${0} completed."


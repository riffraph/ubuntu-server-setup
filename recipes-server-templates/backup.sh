#!/bin/bash

# Script to back up the database and media files

# Depends on the environment file used by Tandoor recipes

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ENVIRONMENT_FILE="_env_file_"
DATE=$(date +%d-%m-%y)
BACKUP_FOLDER="_backup_folder_/${DATE}"


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


mkdir -p ${BACKUP_FOLDER}

postgresUser=$(grep "POSTGRES_USER=" ${SCRIPT_FOLDER}/${ENVIRONMENT_FILE} | sed 's/.*=//')

echo "$(date "+%d.%m.%Y %T") INFO: Backing up database to ${BACKUP_FOLDER}."
# see the recipes-docker-compose.yaml for how the volumes are mapped
docker exec -it recipes-db pg_dumpall -U ${postgresUser} -f /var/lib/postgresql/data/dbbackup.sql 

mv ${SCRIPT_FOLDER}/postgresql/dbbackup.sql ${BACKUP_FOLDER}/


echo "$(date "+%d.%m.%Y %T") INFO: ${0} completed."


#!/bin/bash

# Purpose of this script is to manage the files stored locally

# This script is responsible for removing files from the local folder

# TODO: copy files from remote to local when path is added to the retain list

LOCK_FILE="${SCRIPT_FOLDER}/manage-cache.lock"

RETENTION_PERIOD=_retention_period_ # in days
RCLONE_CONFIG="_rclone_config_"
REMOTE_NAME="_rclone_remote_"
LOCAL_FOLDER="_local_folder_"
LOCAL_MAX_SIZE="_local_max_" # set this for the maximum amount of disk space you want the local folder to user. Be aware that you need to also budget for the rclone cache and operating system + apps
RETAIN_LIST="_retain_list_"
TMP_DIR="_tmp_dir_"

SUBFOLDERS=tv,movies,backup


function shouldFileBeRetained() {
    local retainList=${1}
    local file=${2}

    subDir=$(dirname "${file}" | cut -d'/' -f6-)

    if grep -Fq "${subDir}" ${retainList};
    then
        # retain
        return 0
    else
        # do not retain
        return 1
    fi
}

# get the files that have been backed up, i.e. in local and in remote
# the list of files are saved in path specified by outputPath
function getBackedUpFiles() {
    local subFolder=${1}
    local outputPath=${2}

    if [[ -e ${outputPath} ]];
    then
        rm ${outputPath}
    fi

    rclone check ${LOCAL_FOLDER}/${subFolder} ${REMOTE_NAME}:${subFolder} \
            --config=${RCLONE_CONFIG} \
            --one-way \
            --size-only \
            --match ${outputPath} \
            > /dev/null 2>&1
}


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


echo "$(date "+%d.%m.%Y %T") INFO: Checking if this script is already running."
if [[ -f "${LOCK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: Exiting script as already running."
	exit
else
	echo "$(date "+%d.%m.%Y %T") INFO: Script not running - proceeding."
	touch ${LOCK_FILE}
fi


for subFolder in ${SUBFOLDERS//,/ }
do
    # get the files that have been backed up
    mkdir -p ${TMP_DIR}
    backedUpFiles="${TMP_DIR}/"${subFolder}-matching-files""
    getBackedUpFiles ${subFolder} ${backedUpFiles}

    # find files older than the retention period
    oldFiles=$(find ${LOCAL_FOLDER}/${subFolder} -type f -mtime "+${RETENTION_PERIOD}" -print)

    # check each file to see if in retain list
    while read -r file;
    do
        if [ -z ${file} ];
        then
            continue
        fi

        # check if the file has been backed up
        if grep -Fq "$(basename "${file}")" ${backedUpFiles};
        then
            # check if the file should be retained
            if ! shouldFileBeRetained ${RETAIN_LIST} "${file}";
            then
                rm "${file}"
            fi
        fi
    done <<< ${oldFiles}

    # recusively delete folders which do not contain files
    find ${LOCAL_FOLDER}/${subFolder}/* -type d -empty -delete
done

rm ${LOCK_FILE}


echo "$(date "+%d.%m.%Y %T") INFO: ${0} completed."
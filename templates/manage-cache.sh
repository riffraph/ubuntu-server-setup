#!/bin/bash

# purpose of this script is to manage the files stored locally

RETENTION_PERIOD=_retention_period_ # in days
RCLONE_CONFIG="_rclone_config_"
REMOTE_NAME="_rclone_remote_"
LOCAL_FILES="_local_files_"
LOCAL_MAX_SIZE="_local_max_" # set this for the maximum amount of disk space you want the local folder to user. Be aware that you need to also budget for the rclone cache and operating system + apps
RETAIN_LIST="_retain_list_"
TMP_DIR="_tmp_dir_"

CATEGORIES=tv,movies

function shouldFileBeRetained() {
    local retainList=${1}
    local file=${2}

    if grep -Fxq "$(dirname ${file})" ${retainList};
    then
        return 0
    else
        return 1
    fi
}

# get the files that have been backed up, i.e. in local and in remote
# the list of files are saved in path specified by outputPath
function getBackedUpFiles() {
    local category=${1}
    local outputPath=${2}

    rm ${outputPath}

    rclone check ${LOCAL_FILES}/${REMOTE_NAME}/${category} ${REMOTE_NAME}:${category} \
            --config=${RCLONE_CONFIG} \
            --one-way \
            --size-only \
            --match ${outputPath} \
            > /dev/null 2>&1
}


for category in ${CATEGORIES//,/ }
do
    # get the files that have been backed up
    backedUpFiles="${TMP_DIR}/"${category}-matching-files""
    getBackedUpFiles ${category} ${backedUpFiles}

    # find files older than the retention period
    echo "INFO: finding old files in ${LOCAL_FILES}/${category}"
    oldFiles=$(find ${LOCAL_FILES}/${category} -mtime +${RETENTION_DAYS} -print0)

    # check each file to see if in retain list
    for file in oldFiles;
    do
        # check if the file has been backed up
        if grep -Fxq "${file}" ${backedUpFiles};
        then
            # check if the file should be retained
            if ! shouldFileBeRetained ${RETAIN_LIST} ${file};
            then
                echo "rm ${file}"

                # remove the directory if empty 
                dir=$(dirname ${file})
                if [ -z "$(ls -A ${dir})" ]; 
                then
                    echo "rmdir ${dir}"
                fi
            fi
        do
    done
done

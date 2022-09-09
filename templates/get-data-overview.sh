#!/bin/bash

# purpose of this script is to provide an overview on the data that is stored locally and on the remote


RCLONE_CONFIG="_rclone_config_"
REMOTE_NAME="_rclone_remote_"
LOCAL_FILES="_local_files_"
LOCAL_MAX_SIZE="_local_max_" # set this for the maximum amount of disk space you want the local folder to user. Be aware that you need to also budget for the rclone cache and operating system + apps
RETAIN_LIST="_retain_list_"
TMP_DIR="_tmp_dir_"


# reconcile difference between the local folder and the remote folder
# it only determines if the local files exists on the remove and compares the file size if they do
function reconcile() {
    local dir=${1}

    echo "DEBUG: checking backup status for ${dir}"
    rclone check ${LOCAL_FILES}/${REMOTE_NAME}/${dir} ${REMOTE_NAME}:${dir} \
        --config=${RCLONE_CONFIG} \
        --one-way \
        --size-only \
        --missing-on-src ${TMP_DIR}/"${dir}-missing-files" \
        > /dev/null 2>&1
}


# check that state of files that have been marked to be retained in the cache
function checkIfCached() {
    missingFilesLog="missing-files"

    if [ -f ${missingFilesLog} ];
    then
        rm ${missingFilesLog}
    fi

    # read retain list
    while read -r line;
    do
        echo "DEBUG: checking if ${line} is cached"
        # check those paths exist on the local
        rclone check ${REMOTE_NAME}:"${line}" ${LOCAL_FILES}/${REMOTE_NAME}/"${line}" \
            --config=${RCLONE_CONFIG} \
            --one-way \
            --size-only \
            --missing-on-dst ${TMP_DIR}/tmp-missing \
            > /dev/null 2>&1
        cat tmp-missing >> ${missingFilesLog}
        rm tmp-missing
    done < ${RETAIN_LIST}

    if [ -f ${missingFilesLog} ];
    then
        missingFilesCount=$(cat ${missingFilesLog} | wc -l)
        rm ${missingFilesLog}

        if (( $missingFilesCount > 0 ));
        then
            echo "WARNING: Cache is missing ${missingFilesCount} files"
        fi
    fi
}


function checkDiskUsage() {
    echo "DEBUG: getting disk usage"
    currentSize=$(du -hs /user/local | cut -f 1)
    echo "${currentSize} of ${LOCAL_MAX_SIZE} is used"
}


function getOverview() {
    # report on the state of backup
    reconcile "tv"
    reconcile "movies"

    # report on state of the cache
    checkIfCached

    # check disk usage
    checkDiskUsage
}

getOverview
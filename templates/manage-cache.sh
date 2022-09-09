#!/bin/bash

# purpose of this script is to manage the files stored locally

# TODO: copy files from remote to local when path is added to the retain list

set -e

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
    local category=${1}
    local outputPath=${2}

    if [[ -e ${outputPath} ]];
    then
        rm ${outputPath}
    fi

    rclone check ${LOCAL_FILES}/${category} ${REMOTE_NAME}:${category} \
            --config=${RCLONE_CONFIG} \
            --one-way \
            --size-only \
            --match ${outputPath} \
            > /dev/null 2>&1
}


for category in ${CATEGORIES//,/ }
do
    # get the files that have been backed up
    mkdir -p ${TMP_DIR}
    backedUpFiles="${TMP_DIR}/"${category}-matching-files""
    getBackedUpFiles ${category} ${backedUpFiles}

    # find files older than the retention period
    oldFiles=$(find ${LOCAL_FILES}/${category} -type f -mtime "+${RETENTION_PERIOD}" -print)

    # check each file to see if in retain list
    while read -r file;
    do
        # check if the file has been backed up
        if grep -Fq "$(basename "${file}")" ${backedUpFiles};
        then
            # check if the file should be retained
            if ! shouldFileBeRetained ${RETAIN_LIST} "${file}";
            then
                rm "${file}"

                # remove the directory if empty
                dir=$(dirname "${file}")
                if [ -z "$(ls -A "${dir}")" ];
                then
                    rmdir "${dir}"
                fi
            fi
        fi
    done <<< ${oldFiles}
done
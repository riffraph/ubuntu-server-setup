#!/bin/bash

# Script to set up the data layer

# Purpose is to automate the creation of the folder structures and associated mechanisms such as 
# connecting to a remote data provider (e.g Google Drive) and merging the local and remote data 
# so applications are unaware of the location

# There are 3 folders; local, remote and merged. 

# The design is that downloads will be to the local folder and the upload of data to the remote is
# handled asynchonorously by a separate script.
# After data has been uploaded from local to the remote, the local copy is deleted asynchronously 
# by yet another script. This is where logic to retain the data locally is implemented, and is
# effectively a cache.
# Remote data is accessible in the merged folder, but only as read only. Changes to remote can only
# be performed by running rclone upload.
# Local data is also accessible in the merged folder and can be written and deleted. 


set -e

TEMPLATES_FOLDER="data-templates"
OUTPUT_FOLDER="/usr/data-scripts"
CONFIG_FILE="config"

DATA_ROOT_FOLDER="/mnt/user" # top level folder to organise the local, remote and merged folders under
LOCAL_FOLDER="${DATA_ROOT_FOLDER}/local" # local files 
REMOTE_FOLDER="${DATA_ROOT_FOLDER}/remote" # where your rclone remote will be located
REMOTE_CACHE_FOLDER="${DATA_ROOT_FOLDER}/remote_cache" # where your rclone cache files are located
MERGED_FOLDER="${DATA_ROOT_FOLDER}/merged" # where your merged folder will be located
SUB_FOLDERS=\{"backup"\} # comma separated list of folders to create 


function main() {
    echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."
    

    if [[ ! -e ${OUTPUT_FOLDER} ]];
    then
        mkdir -p ${OUTPUT_FOLDER}
    fi

    ./generate-data-scripts.sh ${OUTPUT_FOLDER}


    # create folder structure 
    echo "$(date "+%d.%m.%Y %T") INFO: Creating folder structure for data."
    eval mkdir -p ${LOCAL_FOLDER}/"${SUB_FOLDERS}"
    mkdir -p ${REMOTE_FOLDER}
    mkdir -p ${REMOTE_CACHE_FOLDER}
    mkdir -p ${MERGED_FOLDER}


    echo "$(date "+%d.%m.%Y %T") INFO: Setting up MergerFS."
    setupMergerfs ${LOCAL_FOLDER} ${REMOTE_FOLDER} ${MERGED_FOLDER}


    echo "$(date "+%d.%m.%Y %T") INFO: Installing RClone."
    installRClone

    # 3. set up an Google Oauth Client Id by following: https://rclone.org/drive/#making-your-own-client-id
    # 4. run sudo rclone config to create 2 remotes. A remote of type Google Drive and another remote of type Crypt.

    echo "You will need to use rclone config to set up:"
    echo "1. oath client id" 
    echo "2. authenticate with Google Drive"
    echo "3. passwords for encryption"

    cp ${TEMPLATES_FOLDER}/rclone.conf ${OUTPUT_FOLDER}/
    rclone config --config="${OUTPUT_FOLDER}/rclone.conf"

    (crontab -l 2>/dev/null; echo "*/5 * * * * ${OUTPUT_FOLDER}/mount-remote.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "*/15 * * * * ${OUTPUT_FOLDER}/upload-to-remote.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "@reboot ${OUTPUT_FOLDER}/clean-up.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "*/30 * * * * ${OUTPUT_FOLDER}/manage-cache.sh") | crontab -u root -

    ${OUTPUT_FOLDER}/mount-remote.sh


    echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete"
}

function installRClone() {
    tmpDir="tmp"
    if [[ ! -e ${tmpDir} ]]; 
    then
        mkdir -p ${tmpDir}
    fi
    cd ${tmpDir}

    # from https://rclone.org/install/
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
    unzip rclone-current-linux-amd64.zip
    cd rclone-*-linux-amd64
    cp rclone /usr/bin/
    chown root:root /usr/bin/rclone
    chmod 755 /usr/bin/rclone

    # install rclone man page
    sudo mkdir -p /usr/local/share/man/man1
    sudo cp rclone.1 /usr/local/share/man/man1/
    sudo mandb

    cd ../..
    rm -rf ${tmpDir}
}

function setupMergerfs() {
    local LOCAL_FOLDER=${1}
    local REMOTE_FOLDER=${2}
    local MERGED_FOLDER=${3}

    apt install -y mergerfs

    # add the mergerfs mount to fstab and start mount 
	if ! grep -q 'init-mergermount' /etc/fstab; 
	then
    # Create mergerfs mount
		echo "$(date "+%d.%m.%Y %T") INFO: Creating mergerfs mount."
		printf "# init-mergermount\n${LOCAL_FOLDER}=RW:${REMOTE_FOLDER}=RO ${MERGED_FOLDER} fuse.mergerfs async_read=false,use_ino,allow_other,func.getattr=newest,category.action=all,category.create=ff,cache.files=partial,dropcacheonclose=true 0 0\n" >> /etc/fstab
		systemctl daemon-reload
		mount -a
	fi
}


main
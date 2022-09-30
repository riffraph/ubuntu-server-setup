#!/bin/bash

# Script to upload from the local folder to the remote folder

# this was originally forked from https://github.com/BinsonBuzz/unraid_rclone_mount.git

# Purpose of this script:
# * control the uploading of files from the local folder to the remote folder
# * to be used when you don't want to write directly to remote

# It depends on RClone

# mountcheck - empty file created by prepare-data-layer.sh to signal whether the remote mount was successful
# upload-to-remote.lock - empty file created locally to indicate whether this script is already running.

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOCK_FILE="${SCRIPT_FOLDER}/upload-to-remote.lock"
MOUNT_CHECK_FILE="mountcheck"

LOCAL_FOLDER="_local_folder_" # location of the local files and MountFolders you want to upload without trailing slash to rclone e.g. /mnt/user/local. Enter 'ignore' to disable

REMOTE_FOLDER="_remote_folder_" # where your rclone remote will be located without trailing slash  e.g. /mnt/user/remote

RCLONE_CONFIG="_rclone_config_"
RCLONE_COMMAND="move" # choose your rclone command e.g. move, copy, sync
RCLONE_REMOTE_NAME="_rclone_remote_" # Name of rclone remote mount WITHOUT ':'.
MINIMUM_AGE="15m" # sync files suffix ms|s|m|h|d|w|M|y
MOD_SORT="ascending" # "ascending" oldest files first, "descending" newest files first

# Bandwidth limits: specify the desired bandwidth in kBytes/s, or use a suffix b|k|M|G. Or 'off' or '0' for unlimited.  The script uses --drive-stop-on-upload-limit which stops the script if the 750GB/day limit is achieved, so you no longer have to slow 'trickle' your files all day if you don't want to e.g. could just do an unlimited job overnight.
BWLimit1Time="01:00"
BWLimit1="off"
BWLimit2Time="08:00"
BWLimit2="15M"
BWLimit3Time="16:00"
BWLimit3="12M"

# OPTIONAL SETTINGS

# Add extra commands or filters
Command1="--exclude downloads/**"
Command2=""
Command3=""
Command4=""
Command5=""
Command6=""
Command7=""
Command8=""

# Bind the mount to an IP address
CreateBindMount="N" # Y/N. Choose whether or not to bind traffic to a network adapter.
RCloneMountIP="192.168.1.253" # Choose IP to bind upload to.
NetworkAdapter="eth0" # choose your network adapter. eth0 recommended.
VirtualIPNumber="1" # creates eth0:x e.g. eth0:1.


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


echo "$(date "+%d.%m.%Y %T") INFO: *** Files will be copied from ${LOCAL_FOLDER} to ${RCLONE_REMOTE_NAME} ***"

#######  Check if script already running  ##########
echo "$(date "+%d.%m.%Y %T") INFO: *** Starting upload-to-remote script for ${RCLONE_REMOTE_NAME} ***"
if [[ -f "${LOCK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: Exiting as script already running."
	exit
else
	echo "$(date "+%d.%m.%Y %T") INFO: Script not running - proceeding."
	touch ${LOCK_FILE}
fi


#######  check if rclone installed  ##########
echo "$(date "+%d.%m.%Y %T") INFO: Checking if rclone installed successfully."
if [[ -f "${REMOTE_FOLDER}/${MOUNT_CHECK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: rclone installed successfully - proceeding with upload."
else
	echo "$(date "+%d.%m.%Y %T") INFO: rclone not installed - will try again later."
	rm ${LOCK_FILE}
	exit
fi


#######  Upload files  ##########

# Check bind option
if [[  $CreateBindMount == 'Y' ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: *** Checking if IP address ${RCloneMountIP} already created for upload to remote ${RCLONE_REMOTE_NAME}"
	ping -q -c2 $RCloneMountIP > /dev/null # -q quiet, -c number of pings to perform
	if [ $? -eq 0 ]; then # ping returns exit status 0 if successful
		echo "$(date "+%d.%m.%Y %T") INFO: *** IP address ${RCloneMountIP} already created for upload to remote ${RCLONE_REMOTE_NAME}"
	else
		echo "$(date "+%d.%m.%Y %T") INFO: *** Creating IP address ${RCloneMountIP} for upload to remote ${RCLONE_REMOTE_NAME}"
		ip addr add $RCloneMountIP/24 dev $NetworkAdapter label $NetworkAdapter:$VirtualIPNumber
	fi
else
	RCloneMountIP=""
fi

# process files
	rclone copy ${LOCAL_FOLDER} ${RCLONE_REMOTE_NAME}: \
	--config=${RCLONE_CONFIG} \
	--user-agent="${RCLONE_REMOTE_NAME}" \
	-vv \
	--buffer-size 512M \
	--drive-chunk-size 512M \
	--tpslimit 8 \
	--checkers 8 \
	--transfers 4 \
	--order-by modtime,$MOD_SORT \
	$Command1 $Command2 $Command3 $Command4 $Command5 $Command6 $Command7 $Command8 \
	--exclude *fuse_hidden* \
	--exclude *_HIDDEN \
	--exclude .recycle** \
	--exclude .Recycle.Bin/** \
	--exclude *.backup~* \
	--exclude *.partial~* \
	--drive-stop-on-upload-limit \
	--bwlimit "${BWLimit1Time},${BWLimit1} ${BWLimit2Time},${BWLimit2} ${BWLimit3Time},${BWLimit3}" \
	--bind=$RCloneMountIP


rm ${LOCK_FILE}


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."


exit

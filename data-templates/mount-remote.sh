#!/bin/bash

# Script to set up volumes on the machine

# this was originally forked from https://github.com/BinsonBuzz/unraid_rclone_mount.git

# Purpose of this script is to mount the remote folder
# It depends on RClone it will ensure that this is running and it will create files on the file system
# for other scripts to be aware of the state

# mountcheck - empty file created locally and copied to the remote. If mount_check can be found in the
# remote after mounting, it implies the mount was successful. It is also used to indicate if the merge 
# was successful.
# _prepare-data-layer.lock - empty file created locally to indicate whether this script is already running.

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOCK_FILE="${SCRIPT_FOLDER}/mount-remote.lock"
MOUNT_CHECK_FILE="mountcheck"

ROOT_FOLDER="_root_folder_" # top level folder to organise the local, remote and merged folders under

REMOTE_FOLDER="_remote_folder_" # where your rclone remote will be located

RCLONE_CONFIG="_rclone_config_"
RCLONE_REMOTE_NAME="_rclone_remote_" # Name of rclone remote mount WITHOUT ':'. NOTE: Choose your encrypted remote for sensitive data
RCLONE_DIR_CACHE_TIME="720h" # rclone dir cache time
RCLONE_CACHE_MODE="minimal"
RCLONE_CACHE_FOLDER="_remote_cache_folder_" # location of rclone cache files
RCLONE_CACHE_MAX_SIZE="_rclone_cache_max_" # Maximum size of rclone cache
RCLONE_CACHE_MAX_AGE="_rclone_cache_age_" # Maximum age of cache files

MERGED_FOLDER="_merged_folder_" # where your merged folder will be located

# OPTIONAL SETTINGS for rclone

# Add extra commands or filters
Command1="--rc"
Command2=""
Command3=""
Command4=""
Command5=""
Command6=""
Command7=""
Command8=""

CreateBindMount="N" # Y/N. Choose whether to bind traffic to a particular network adapter
RCloneMountIP="192.168.1.252" # My unraid IP is 172.30.12.2 so I create another similar IP address
NetworkAdapter="eth0" # choose your network adapter. eth0 recommended
VirtualIPNumber="2" # creates eth0:x e.g. eth0:1.  I create a unique virtual IP addresses for each mount & upload so I can monitor and traffic shape for each of them


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


#######  Check if script is already running  #######
echo "$(date "+%d.%m.%Y %T") INFO: *** Starting mount of remote ${RCLONE_REMOTE_NAME}"
echo "$(date "+%d.%m.%Y %T") INFO: Checking if this script is already running."
if [[ -f "${LOCK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: Exiting script as already running."
	exit
else
	echo "$(date "+%d.%m.%Y %T") INFO: Script not running - proceeding."
	touch ${LOCK_FILE}
fi

####### Checking have connectivity #######

echo "$(date "+%d.%m.%Y %T") INFO: *** Checking if online"
ping -q -c2 google.com > /dev/null # -q quiet, -c number of pings to perform
if [ $? -eq 0 ]; then # ping returns exit status 0 if successful
	echo "$(date "+%d.%m.%Y %T") PASSED: *** Internet online"
else
	echo "$(date "+%d.%m.%Y %T") FAIL: *** No connectivity.  Will try again on next run"
	rm ${LOCK_FILE}
	exit
fi

#######  Create Rclone Mount  #######

# Check If Rclone Mount Already Created
if [[ -f "${REMOTE_FOLDER}/${MOUNT_CHECK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: Success ${RCLONE_REMOTE_NAME} remote is already mounted."
else
	echo "$(date "+%d.%m.%Y %T") INFO: Mount not running. Will now mount ${RCLONE_REMOTE_NAME} remote."
# Creating mountcheck file in case it doesn't already exist
	echo "$(date "+%d.%m.%Y %T") INFO: Recreating mountcheck file for ${RCLONE_REMOTE_NAME} remote."
	touch ${SCRIPT_FOLDER}/${MOUNT_CHECK_FILE}
	rclone copy --config=${RCLONE_CONFIG} ${SCRIPT_FOLDER}/${MOUNT_CHECK_FILE} $RCLONE_REMOTE_NAME: -vv --no-traverse
	rm ${SCRIPT_FOLDER}/${MOUNT_CHECK_FILE}
	
# Check bind option
	if [[  $CreateBindMount == 'Y' ]]; then
		echo "$(date "+%d.%m.%Y %T") INFO: *** Checking if IP address ${RCloneMountIP} already created for remote ${RCLONE_REMOTE_NAME}"
		ping -q -c2 $RCloneMountIP > /dev/null # -q quiet, -c number of pings to perform
		if [ $? -eq 0 ]; then # ping returns exit status 0 if successful
			echo "$(date "+%d.%m.%Y %T") INFO: *** IP address ${RCloneMountIP} already created for remote ${RCLONE_REMOTE_NAME}"
		else
			echo "$(date "+%d.%m.%Y %T") INFO: *** Creating IP address ${RCloneMountIP} for remote ${RCLONE_REMOTE_NAME}"
			ip addr add $RCloneMountIP/24 dev $NetworkAdapter label $NetworkAdapter:$VirtualIPNumber
		fi
		echo "$(date "+%d.%m.%Y %T") INFO: *** Created bind mount ${RCloneMountIP} for remote ${RCLONE_REMOTE_NAME}"
	else
		RCloneMountIP=""
		echo "$(date "+%d.%m.%Y %T") INFO: *** Creating mount for remote ${RCLONE_REMOTE_NAME}"
	fi

# create rclone mount
	rclone mount \
	--config=${RCLONE_CONFIG} \
	$Command1 $Command2 $Command3 $Command4 $Command5 $Command6 $Command7 $Command8 \
	--allow-other \
	--umask 000 \
	--dir-cache-time $RCLONE_DIR_CACHE_TIME \
	--attr-timeout $RCLONE_DIR_CACHE_TIME \
	--log-level INFO \
	--poll-interval 10s \
	--cache-dir=${RCLONE_CACHE_FOLDER} \
	--drive-pacer-min-sleep 10ms \
	--drive-pacer-burst 1000 \
	--vfs-cache-mode $RCLONE_CACHE_MODE \
	--vfs-cache-max-size $RCLONE_CACHE_MAX_SIZE \
	--vfs-cache-max-age $RCLONE_CACHE_MAX_AGE \
	--vfs-read-ahead 1G \
	--bind=$RCloneMountIP \
	$RCLONE_REMOTE_NAME: ${REMOTE_FOLDER} &

# Check if Mount Successful
	echo "$(date "+%d.%m.%Y %T") INFO: sleeping for 5 seconds"
# slight pause to give mount time to finalise
	sleep 5
	echo "$(date "+%d.%m.%Y %T") INFO: continuing..."
	if [[ -f "${REMOTE_FOLDER}/${MOUNT_CHECK_FILE}" ]]; then
		echo "$(date "+%d.%m.%Y %T") INFO: Successful mount of ${RCLONE_REMOTE_NAME} mount."
	else
		echo "$(date "+%d.%m.%Y %T") CRITICAL: ${RCLONE_REMOTE_NAME} mount failed - please check for problems.  Stopping dockers"
		rm ${LOCK_FILE}
		exit
	fi
fi


####### Check MergerFS Mount #######
echo "$(date "+%d.%m.%Y %T") INFO: Checking if ${RCLONE_REMOTE_NAME} mergerfs mount is operational."

if [[ -f "${MERGED_FOLDER}/${MOUNT_CHECK_FILE}" ]]; then
	echo "$(date "+%d.%m.%Y %T") INFO: Check successful, ${RCLONE_REMOTE_NAME} mergerfs mount in operating."
else
	echo "$(date "+%d.%m.%Y %T") CRITICAL: ${RCLONE_REMOTE_NAME} mergerfs mount failed."
fi

rm ${LOCK_FILE}


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

exit

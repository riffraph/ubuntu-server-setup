#!/bin/bash

# prepares mount-remote.sh
function prepMountScript() {
    local scriptPath=${1}
    local dataRootFolder=${2}
    local rcloneConfigPath=${3}

    remoteFolder="${dataRootFolder}/remote"
    remoteCacheFolder="${dataRootFolder}/remote-cache"
    mergedFolder="${dataRootFolder}/merged"

    rcloneRemoteName="gdrive-vfs"
    rcloneCacheMaxSize="30G"
    rcloneCacheMaxAge="48h"

    sed -re "s:_root_folder_:${dataRootFolder}:" -i ${scriptPath}
    sed -re "s:_remote_folder_:${remoteFolder}:" -i ${scriptPath}
    sed -re "s:_remote_cache_folder_:${remoteCacheFolder}:" -i ${scriptPath}
    sed -re "s:_merged_folder_:${mergedFolder}:" -i ${scriptPath}

    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s/_rclone_cache_max_/${rcloneCacheMaxSize}/" -i ${scriptPath}
    sed -re "s/_rclone_cache_age_/${rcloneCacheMaxAge}/" -i ${scriptPath}
}

# prepares upload-to-remote.sh
function prepUploadScript() {
    local scriptPath=${1}
    local dataRootFolder=${2}
    local rcloneConfigPath=${3}

    localFolder="${dataRootFolder}/local"
    remoteFolder="${dataRootFolder}/remote"

    rcloneRemoteName="gdrive-vfs"

    sed -re "s:_local_folder_:${localFolder}:" -i ${scriptPath}
    sed -re "s:_remote_folder_:${remoteFolder}:" -i ${scriptPath}
    
    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
}

# prepares data-overview.sh
function prepOverviewScript() {
    local scriptPath=${1}
    local dataRootFolder=${2}
    local rcloneConfigPath=${3}
    local otherDir=${4}

    localFolder="${dataRootFolder}/local"
    retainListPath="${otherDir}/retain_list"
    tmpDirPath="${otherDir}/tmp"
    rcloneRemoteName="gdrive-vfs"
    localMaxSize="140G"

    sed -re "s:_local_folder_:${localFolder}:" -i ${scriptPath}
    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s:_retain_list_:${retainListPath}:" -i ${scriptPath}
    sed -re "s:_tmp_dir_:${tmpDirPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s/_local_max_/${localMaxSize}/" -i ${scriptPath}
}

# prepares manage-cache.sh
function prepManageCacheScript() {
    local scriptPath=${1}
    local dataRootFolder=${2}
    local rcloneConfigPath=${3}
    local otherDir=${4}

    localFolder="${dataRootFolder}/local"
    retainListPath="${otherDir}/retain_list"
    tmpDirPath="${otherDir}/tmp"

    retentionPeriod=1
    rcloneRemoteName="gdrive-vfs"
    localMaxSize="140G"

    sed -re "s:_local_folder_:${localFilesPath}:" -i ${scriptPath}
    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s:_retain_list_:${retainListPath}:" -i ${scriptPath}
    sed -re "s:_tmp_dir_:${tmpDirPath}:" -i ${scriptPath}
    sed -re "s/_retention_period_/${retentionPeriod}/" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s/_local_max_/${localMaxSize}/" -i ${scriptPath}
}

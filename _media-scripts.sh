#!/bin/bash

function prepMaintenanceScripts() {
    local destinationDir=${1}
    local libDir=${2}

    for file in ${destinationDir}/*.sh;
    do
        # update dependency from the script to this folder
        sed -re "s:_libDir_:${libDir}:g" -i ${file}
    done
}

function prepMountScript() {
    local scriptPath=${1}
    rcloneRemoteName="gdrive-vfs"
    rcloneCacheMaxSize="30G"
    rcloneCacheMaxAge="48h"
    dockerApps="nzbget plex sonarr radarr"
    rcloneConfigPath="/usr/mediaserver/rclone.conf"
    rcloneMountPath="/mnt/user/mount_rclone"
    localFilesPath="/mnt/user/local"
    mergerfsMountPath="/mnt/user/mount_mergerfs"
    syncContainerIpsScript="sync-container-ips.sh"

    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s:_rclone_files_:${rcloneMountPath}:" -i ${scriptPath}
    sed -re "s:_local_files_:${localFilesPath}:" -i ${scriptPath}
    sed -re "s/_rclone_cache_max_/${rcloneCacheMaxSize}/" -i ${scriptPath}
    sed -re "s/_rclone_cache_age_/${rcloneCacheMaxAge}/" -i ${scriptPath}
    sed -re "s:_merged_files_:${mergerfsMountPath}:" -i ${scriptPath}
    sed -re "s/_docker_apps_/${dockerApps}/" -i ${scriptPath}
    sed -re "s/_sync_container_ips_script_/${syncContainerIpsScript}/" -i ${scriptPath}
}


function prepUploadScript() {
    local scriptPath=${1}
    rcloneRemoteName="gdrive-vfs"
    rcloneUploadRemoteName="gdrive-vfs"
    rcloneConfigPath="/usr/mediaserver/rclone.conf"
    rcloneMountPath="/mnt/user/mount_rclone"
    localFilesPath="/mnt/user/local"
    
    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s/_rclone_upload_remote_/${rcloneUploadRemoteName}/" -i ${scriptPath}
    sed -re "s:_rclone_files_:${rcloneMountPath}:" -i ${scriptPath}
    sed -re "s:_local_files_:${localFilesPath}:" -i ${scriptPath}
}


function prepOverviewScript() {
    local scriptPath=${1}
    rcloneConfigPath="/usr/mediaserver/rclone.conf"
    rcloneRemoteName="gdrive-vfs"
    localFilesPath="/mnt/user/local"
    localMaxSize="140G"
    retainListPath="/mnt/user/appdata/other/retain_list"
    tmpDirPath="/mnt/user/appdata/other/tmp"

    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s:_local_files_:${localFilesPath}:" -i ${scriptPath}
    sed -re "s/_local_max_/${localMaxSize}/" -i ${scriptPath}
    sed -re "s:_retain_list_:${retainListPath}:" -i ${scriptPath}
    sed -re "s:_tmp_dir_:${tmpDirPath}:" -i ${scriptPath}
}


function prepManageCacheScript() {
    local scriptPath=${1}
    retentionPeriod=1
    rcloneConfigPath="/usr/mediaserver/rclone.conf"
    rcloneRemoteName="gdrive-vfs"
    localFilesPath="/mnt/user/local"
    localMaxSize="140G"
    retainListPath="/mnt/user/appdata/other/retain_list"
    tmpDirPath="/mnt/user/appdata/other/tmp"

    sed -re "s/_retention_period_/${retentionPeriod}/" -i ${scriptPath}
    sed -re "s:_rclone_config_:${rcloneConfigPath}:" -i ${scriptPath}
    sed -re "s/_rclone_remote_/${rcloneRemoteName}/" -i ${scriptPath}
    sed -re "s:_local_files_:${localFilesPath}:" -i ${scriptPath}
    sed -re "s/_local_max_/${localMaxSize}/" -i ${scriptPath}
    sed -re "s:_retain_list_:${retainListPath}:" -i ${scriptPath}
    sed -re "s:_tmp_dir_:${tmpDirPath}:" -i ${scriptPath}
}


function prepSetPermissionsScript() {
    local scriptPath=${1}
    group="media"
    downloadsDir="/mnt/user/local/gdrive-vfs/downloads"
    tvDir="/mnt/user/local/gdrive-vfs/tv"
    moviesDir="/mnt/user/local/gdrive-vfs/movies"

    sed -re "s/_group_/${group}/" -i ${scriptPath}
    sed -re "s:_downloads_:${downloadsDir}:" -i ${scriptPath}
    sed -re "s:_tv_:${tvDir}:" -i ${scriptPath}
    sed -re "s:_movies_:${moviesDir}:" -i ${scriptPath}
}
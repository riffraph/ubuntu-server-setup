#!/bin/bash

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


function installMergerfs() {
    apt install -y mergerfs
}


# Using Google Drive as a data provider, where the files stored in google drive are encrypted
# 1. install mergerfs
# 1. install RClone
# 2. set up an Google Oauth Client Id by following: https://rclone.org/drive/#making-your-own-client-id
# 3. run sudo rclone config to create 2 remotes. A remote of type Google Drive and another remote of type Crypt.
# 4. clone these scripts https://github.com/BinsonBuzz/unraid_rclone_mount and adjust parameters as necessary
# 5. schedule the running of the scripts in crontab
#    - @reboot /ubuntu... /unraid .../rclone_unmount
#    - */10 * * * * /ubuntu... /unraid .../rclone_mount
#    - */10 * * * * /ubuntu... /unraid .../rclone_upload


function prepMountScript() {
    local scriptPath=${1}
    rcloneRemoteName="gdrive-vfs"
    rcloneCacheMaxSize="30G"
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
    retentionPeriod=7
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


function mountDrive() {
    local scriptDir=${1}

    chmod g+x ${scriptDir}/rclone_mount
    chmod g+x ${scriptDir}/rclone_upload
    chmod g+x ${scriptDir}/rclone_unmount

    prepMountScript ${scriptDir}/rclone_mount
    prepUploadScript ${scriptDir}/rclone_upload

    (crontab -l 2>/dev/null; echo "*/10 * * * * ${scriptDir}/rclone_mount") | crontab -u root -
    (crontab -l 2>/dev/null; echo "*/10 * * * * ${scriptDir}/rclone_upload") | crontab -u root -
    (crontab -l 2>/dev/null; echo "@reboot ${scriptDir}/rclone_unmount") | crontab -u root -
    (crontab -l 2>/dev/null; echo "*/10 * * * * ${scriptDir}/manage-cache.sh") | crontab -u root -
    (crontab -l 2>/dev/null; echo "*/30 * * * * ${scriptDir}/set-permissions.sh") | crontab -u root -


    ${scriptDir}/rclone_mount
}
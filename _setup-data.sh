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
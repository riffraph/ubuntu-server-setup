#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

function includeDependencies() {
    source "${current_dir}/utils.sh"
    source "${current_dir}/setup-environment.sh"
    source "${current_dir}/setup-ssh.sh"
    source "${current_dir}/setup-network.sh"
    source "${current_dir}/setup-media-server.sh"
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

function main() {
    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM


    # 1. create user with sudo and home directory
    # 2. set ssh port
    # 3. set up public ssh key for the new user
    # 3. disable IPv6
    # 4. set up firewall
    # 5. update apt packages and upgrade installed packages
    # 6. install unzip
    # 7. install zsh
    # 8. install docker
    # 9. set up docker network
    # 10. set up rclone
    # 11. set up dvr directory structure
    # 12. get and run media server setup


    # 1. create user account
    echo "Setting up user account..." >&3
    read -rp "Enter the username of the new user account: " username
    addUserAccount "${username}"
    disableSudoPassword "${username}"

    read -rp "Paste in the public SSH key for the ${username}:\n" sshKey
    addSSHKey "${username}" "${sshKey}"
    
    # Update packages
    echo "Updating packages..." >&3
    apt update && apt upgrade && apt autoremove


    # Set up ssh
    echo "Configuring SSH..." >&3
    read -rp "Enter the port for SSH to run on: " sshPort
    changeSSHConfig "${sshPort}"
    

    # Configure system time
    echo "Configuring system time... " >&3
    read -rp "Enter the timezone (e.g. Europe/Berlin):" timezone
    setupTimezone "${timezone}"
    configureNTP


    # Disable IP
    echo "Disabling IPv6..." >&3
    disableIPv6


    # Set up firewall
    echo "Configuring firewall... " >&3
    setupFirewall "${sshPort}"
    

    echo "Restarting services..." >&3

    sudo service ssh restart


    # echo "Installing rclone..." >&3


    # echo "Configuring directory structure..." >&3


    # echo "Installing Docker..." >&3




    if ! hasSwap; then
        setupSwap
    fi

    cleanup

    echo "Setup Done! Log file is located at ${output_file}" >&3
}

function setupSwap() {
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings "10" "50"
}

function hasSwap() {
    [[ "$(sudo swapon -s)" == *"/swapfile"* ]]
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    local filename=${1}
    {
        echo "===================" 
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1
}

function setupTimezone() {
    echo -ne "Enter the timezone for the server (Default is 'Asia/Singapore'):\n" >&3
    read -r timezone
    if [ -z "${timezone}" ]; then
        timezone="Asia/Singapore"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3
}

main

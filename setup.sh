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
    source "${current_dir}/setup-user.sh"
    source "${current_dir}/setup-ssh.sh"
    source "${current_dir}/setup-network.sh"
    source "${current_dir}/setup-media-server.sh"
    source "${current_dir}/setup-media-server.sh"
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

function main() {
    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM
    

    # 1. Configure system time
    echo "Configuring timezone... " >&3
    read -rp "Enter the timezone (default is 'Europe/Berlin'):" timezone
    if [ -z "${timezone}" ]; then
        timezone="Europe/Berlin"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3

    echo "Configuring network time protocol... " >&3
    configureNTP


    # 2. Set up swap space
    if ! hasSwap; then
        setupSwap
    fi


    # 3. create user account
    echo "Setting up user account..." >&3
    read -rp "Enter the username of the new user account: " username
    addUserAccount "${username}"
    disableSudoPassword "${username}"

    read -rp "Paste in the public SSH key for the ${username}:\n" sshKey
    addSSHKey "${username}" "${sshKey}"
    
    # 5. Update packages
    echo "Updating package list and upgrade installed packages..." >&3
    apt update && apt upgrade && apt autoremove


    # 6. Set up ssh
    echo "Configuring SSH..." >&3
    read -rp "Enter the port for SSH to run on: " sshPort
    changeSSHConfig "${sshPort}"
    

    # 7. Disable IPv6
    echo "Disabling IPv6..." >&3
    disableIPv6


    # 8. Set up firewall
    echo "Configuring firewall... " >&3
    setupFirewall "${sshPort}"


    # 9. install miscellaneous packages

    echo "Installing misc packages..." >&3
    apt install unzip zsh
    installOhMyZsh
    installDocker


    echo "Restarting services..." >&3

    sudo service ssh restart


    # Prompt the user to select the server type
    echo "Choose which server to set up. The options are;"
    echo "1. As a test server"
    echo "2. As a media server"
    read -n 1 -rp  "Enter your choice (1 or 2, defaults to neither): " serverType

    case ${serverType} in
        '1')  
            setupAsTestServer
            ;;

        '2')
            setupAsMediaServer
            ;;

        *) # default
            ;;
    esac    


    cleanup

    echo "Setup Done! Log file is located at ${output_file}" >&3
}

function setupAsTestServer() {
    # install vagrant
    apt install vagrant
}

function setupAsMediaServer() {
    # 9. set up docker network
    # 10. set up rclone
    # 11. set up dvr directory structure
    # 12. get and run media server setup

    # echo "Configuring docker network..." >&3

    # echo "Installing rclone..." >&3


    # echo "Configuring directory structure..." >&3


    # echo "Installing Docker..." >&3
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


main

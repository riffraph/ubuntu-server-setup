#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${currentDir}/utils.sh"
    source "${currentDir}/setup-environment.sh"
    source "${currentDir}/setup-user.sh"
    source "${currentDir}/setup-ssh.sh"
    source "${currentDir}/setup-network.sh"
    source "${currentDir}/setup-misc-packages.sh"
    source "${currentDir}/setup-media-server.sh"
}

currentDir=$(getCurrentDir)
includeDependencies
logFile="output.log"

function main() {
    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    # create fd 3, redirect stdout and stderr to the log 
    exec 3>&1 2>&1 1>>${logFile}

    resetLog ${logFile}
    logTimestamp ${logFile}


    # Configure system time
    printAndLog "Configuring timezone... "
    read -rp "Enter the timezone (default is 'Europe/Berlin'):" timezone
    if [ -z "${timezone}" ]; then
        timezone="Europe/Berlin"
    fi
    setTimezone "${timezone}"
    printAndLog "Timezone is set to $(cat /etc/timezone)" 

    printAndLog "Configuring network time protocol... " 
    configureNTP


    # Set up swap space
    if ! hasSwap; then
        setupSwap
    fi

    
    # Update packages
    printAndLog "Updating package list and upgrade installed packages..." 
    apt update
    yes Y | apt upgrade
    apt autoremove


    # Set up ssh
    printAndLog "Configuring SSH..." 
    read -rp "Enter the port for SSH to run on: " sshPort
    changeSSHConfig "${sshPort}"
    

    # Disable IPv6
    printAndLog "Disabling IPv6..." 
    disableIPv6


    # Set up firewall
    printAndLog "Configuring firewall... " 
    setupFirewall "${sshPort}"


    # Install miscellaneous packages

    printAndLog "Installing misc packages..." 
    printAndLog "-- Installing unzip..."
    apt install unzip 
    
    printAndLog "-- Installing Docker engine..."
    installDocker


    # Create user account
    printAndLog "Setting up user account..." 
    read -rp "Enter the username of the new user account: " username
    addUserAccount "${username}" "true"
    disableSudoPassword "${username}"

    read -rp "Paste in the public SSH key for the ${username}: " sshKey
    addSSHKey "${username}" "${sshKey}"

    printAndLog "Run the following command on the machine you want to connect from:"
    printAndLog "      ssh-copy-id -i ~/.ssh/id_rsa.pub -p ${sshPort} ${username}@${host}"


    # printAndLog "-- Installing Zsh..."
    # setupZsh



    # Prompt the user to select the server type
    printAndLog "Choose which server to set up. The options are;"
    printAndLog "1. As a test server"
    printAndLog "2. As a media server"
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

    printAndLog ""
    printAndLog "Setup Done! Log file is located at ${logFile}"
}

function setupAsTestServer() {
    # install vagrant
    printAndLog "Installing Vagrant..."
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
    echo "not implemented"
}


function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

main
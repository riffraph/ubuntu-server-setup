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
    source "${currentDir}/setup-personalisation.sh"
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


    # Create user account
    printAndLog "Setting up user account..." 
    read -rp "Enter the username of the new user account: " username
    addUserAccount "${username}" "true"
    disableSudoPassword "${username}"

    printAndLog "You will not be able to connect via SSH with a username and password!"
    read -rp "Paste in the public SSH key for ${username}: " sshKey
    addSSHKey "${username}" "${sshKey}"


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


    # Install utility packages

    printAndLog "Installing misc packages..." 
    printAndLog "-- Installing unzip..."
    apt install unzip 
    
    printAndLog "-- Installing Docker engine..."
    installDocker


    # Add personal touches
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

    printAndLog "Setup Done! Log file is located at ${logFile}"
}

function setupAsTestServer() {
    # install vagrant
    printAndLog "Installing Vagrant..."
    yes Y | apt install vagrant virtualbox virtualbox-ext-pack
}

function setupAsMediaServer() {
    printAndLog "Create users, groups and directory structure..."
    mediaGroup="media"
    downloaderGroup="downloader"
    plexUsername="plex"
    sonarrUsername="sonarr"
    nzbgetUsername="nzbget"
    createUsersAndDirectoryStructure ${mediaGroup} ${downloaderGroup} ${plexUsername} ${sonarrUsername} ${nzbgetUsername}
    
    printAndLog "Configuring docker network..."
    createDockerNetwork ${mediaGroup} ${downloaderGroup}

    printAndLog "Installing rclone... TODO"
    

    printAndLog "Install and run media server apps..."
    read -rp "Enter your Plex claim: " plexClaim

    plexUID=$(id -u ${plexUsername})
    plexGID=$(getent group ${mediaGroup} | cut -d: -f3)
    sonarrUID=$(id -u ${sonarrUsername})
    sonarrGID=$(getent group ${downloaderGroup} | cut -d: -f3)
    nzbgetUID=$(id -u ${nzbgetUsername})
    nzbgetGID=$(getent group ${downloaderGroup} | cut -d: -f3)

    mediaComposeFile="media-docker-compose.yaml"
    prepMediaCompose ${mediaComposeFile} ${mediaGroup} ${timezone} ${plexUID} ${plexGID} ${plexClaim}

    downloaderComposeFile="downloader-docker-compose.yaml"
    prepDownloaderCompose ${downloaderComposeFile} ${downloaderGroup} ${timezone} ${sonarrUID} ${sonarrGID} ${nzbgetUID} ${nzbgetGID}

    docker compose -f ${mediaComposeFile} up
    docker compose -f ${downloaderComposeFile} up
}


function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

main
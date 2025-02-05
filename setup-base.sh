#!/bin/bash

set -e

function getCurrentDir() {
    local currentDir="${BASH_SOURCE%/*}"
    if [[ ! -d "${currentDir}" ]]; then currentDir="$PWD"; fi
    echo "${currentDir}"
}

function includeDependencies() {
    source "${currentDir}/_utils.sh"
    source "${currentDir}/_setup-environment.sh"
    source "${currentDir}/_setup-user.sh"
    source "${currentDir}/_setup-ssh.sh"
    source "${currentDir}/_setup-network.sh"
    source "${currentDir}/_setup-misc-packages.sh"
    source "${currentDir}/_setup-personalisation.sh"
}

currentDir=$(getCurrentDir)
includeDependencies
logFile=$(basename $0) 
logFile+=".log"


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
    apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y
    apt autoremove


    # Set up ssh
    printAndLog "Configuring SSH..." 
    read -rp "Enter the port for SSH to run on: " sshPort
    changeSSHConfig "${sshPort}"
    

    # Set up firewall
    printAndLog "Configuring network settings ... " 
    disableIPv6
    setupFirewall "${sshPort}"
    setupForwarding


    # Install utility packages

    printAndLog "Installing misc packages..." 
    DEBIAN_FRONTEND=noninteractive apt install -y unzip net-tools nmap acl postfix bzip2
    
    printAndLog "-- Installing Docker engine..."
    installDocker
    disableDockerIPTables


    echo "$(date "+%d.%m.%Y %T") INFO: Setting up automatic upgrade of packages"
    (crontab -l 2>/dev/null; echo "0 5 * * * apt update && apt upgrade -yy && apt autoremove") | crontab -u root -


    cleanup

    printAndLog "Setup Done! Log file is located at ${logFile}"
}


function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

main
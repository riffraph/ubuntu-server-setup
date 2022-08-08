#!/bin/bash


# Update the user account
# Arguments:
#   Account Username
function updateUserAccount() {
    local username=${1}
    
    passwd -d "${username}"
    usermod -aG sudo "${username}"
}


# Add the new user account
# Arguments:
#   Account Username
#   Flag to determine if user account is added silently. (With / Without GECOS prompt)
function addUserAccount() {
    local username=${1}
    local silent_mode=${2}

    if [[ ${silent_mode} == "true" ]]; then
        adduser --disabled-password --gecos '' "${username}"
    else
        adduser --disabled-password "${username}"
    fi

    usermod -aG sudo "${username}"
    passwd -d "${username}"
}


# Add the local machine public SSH Key for the new user account
# Arguments:
#   Account Username
#   Public SSH Key
function addSSHKey() {
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}


function instructUserToAddSSHKey() {
    local username=${1}
    local host=${2}
    local sshPort=${3}

    echo ""
    echo "Run the following command on the machine you want to connect from:"
    echo "      ssh-copy-id -i ~/.ssh/id_rsa.pub -p ${sshPort} ${username}@${host}"
    echo ""
}


# Disables the sudo password prompt for a user account by editing /etc/sudoers
# Arguments:
#   Account username
function disableSudoPassword() {
    local username="${1}"

    cp /etc/sudoers /etc/sudoers.bak
    bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}


# Reverts the original /etc/sudoers file before this script is ran
function revertSudoers() {
    cp /etc/sudoers.bak /etc/sudoers
    rm -rf /etc/sudoers.bak
}

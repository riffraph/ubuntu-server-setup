#!/bin/bash


# Modify the sshd_config file
# shellcheck disable=2116
function changeSSHConfig() {
    local sshPort=${1}

    sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i."$(echo 'old')" /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(Port)([[:space:]]+)(.*)/Port '"${sshPort}"'/' -i /etc/ssh/sshd_config
}
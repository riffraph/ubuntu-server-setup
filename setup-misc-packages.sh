#!/bin/bash

function setupZsh() {
    apt install zsh
    
    # from https://ohmyz.sh/#install
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function installDocker() {
    # following the "Install using the repository method"
    
    # set up apt to repositories over https
    apt install ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    
    # Add Docker’s official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # install docker engine
    apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
}
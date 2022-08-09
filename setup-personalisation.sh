#!/bin/bash


function setupZsh() {
    apt install zsh

    # from https://ohmyz.sh/#install
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}
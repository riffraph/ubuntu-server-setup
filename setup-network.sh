#!/bin/bash


function disableIPv6()
{
    if grep -p 0 /sys/module/ipv6/parameters/disable; then
        sudo sed -re 's/^(\#?)(net.ipv6.conf.all.disable_ipv6=)(.*)/net.ipv6.conf.all.disable_ipv6=1/' -i /etc/sysctl.conf
        sudo sed -re 's/^(\#?)(net.ipv6.conf.default.disable_ipv6=)(.*)/net.ipv6.conf.default.disable_ipv6=1/' -i /etc/sysctl.conf
        sudo sed -re 's/^(\#?)(net.ipv6.conf.lo.disable_ipv6=)(.*)/net.ipv6.conf.lo.disable_ipv6=1/' -i /etc/sysctl.conf

        sudo sysctl -p
    fi
}


function setupFirewall()
{
    local sshPort=${1}

    sudo apt install firewalld

    sudo firewall-cmd --permanent --remove-service=dhcpv6-client
    sudo firewall-cmd --permanent --remove-service=ssh
    sudo firewall-cmd --permanent --add-port=${sshPort}/tcp
}


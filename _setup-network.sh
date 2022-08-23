#!/bin/bash


function disableIPv6()
{
    if grep -P 0 /sys/module/ipv6/parameters/disable; then
        # Update sysctl method ... may not work for later versions on Ubuntu
        if grep 'net.ipv6.conf.all.disable_ipv6' /etc/sysctl.conf
        then
            sed -re 's/^(\#?)(net.ipv6.conf.all.disable_ipv6=)(.*)/net.ipv6.conf.all.disable_ipv6=1/' -i /etc/sysctl.conf
        else
            echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
        fi

        if grep 'net.ipv6.conf.default.disable_ipv6' /etc/sysctl.conf
        then
            sed -re 's/^(\#?)(net.ipv6.conf.default.disable_ipv6=)(.*)/net.ipv6.conf.default.disable_ipv6=1/' -i /etc/sysctl.conf
        else
            echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
        fi
                
        if grep 'net.ipv6.conf.lo.disable_ipv6' /etc/sysctl.conf
        then
            sed -re 's/^(\#?)(net.ipv6.conf.lo.disable_ipv6=)(.*)/net.ipv6.conf.lo.disable_ipv6=1/' -i /etc/sysctl.conf
        else
            echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
        fi
        
        sysctl -p


        # Update GRUB method

        sed -re 's/^(\#?)(GRUB_CMDLINE_LINUX_DEFAULT=)(.*)/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"/' -i /etc/default/grub
        sed -re 's/^(\#?)(GRUB_CMDLINE_LINUX=)(.*)/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' -i /etc/default/grub

        update-grub
    fi
}


function setupFirewall()
{
    local sshPort=${1}

    apt install -y firewalld

    firewall-cmd --permanent --remove-service=dhcpv6-client
    firewall-cmd --permanent --remove-service=ssh
    firewall-cmd --permanent --add-port=${sshPort}/tcp
    firewall-cmd --permanent --zone=public --add-interface eth0
    firewall-cmd --reload
}


function setupForwarding() {
    # allow the forwarding of packets externally
    if grep 'net.ipv4.ip_forward' /etc/sysctl.conf
    then
        sed -re 's/^(\#?)(net.ipv4.ip_forward=)(.*)/net.ipv4.ip_forward=1/' -i /etc/sysctl.conf
    else
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
        
    sysctl -p
}

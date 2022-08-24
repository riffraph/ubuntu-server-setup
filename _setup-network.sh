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

    DEBIAN_FRONTEND=noninteractive apt install -y firewalld

    firewall-cmd --permanent --remove-service=dhcpv6-client
    firewall-cmd --permanent --remove-service=ssh
    firewall-cmd --permanent --add-port=${sshPort}/tcp
    firewall-cmd --permanent --zone=public --add-interface eth0

    # policies for container traffic
    firewall-cmd --permanent --new-zone containers

    firewall-cmd --permanent --new-policy containersToWorld
    firewall-cmd --permanent --policy containersToWorld --add-ingress-zone containers
    firewall-cmd --permanent --policy containersToWorld --add-egress-zone ANY
    firewall-cmd --permanent --policy containersToWorld --add-masquerade
    firewall-cmd --permanent --policy containersToWorld --add-rich-rule='rule service name="ftp" reject'

    firewall-cmd --permanent --new-policy worldToContainers
    firewall-cmd --permanent --policy worldToContainers --add-ingress-zone ANY
    firewall-cmd --permanent --policy worldToContainers --add-egress-zone ANY

    firewall-cmd --permanent --new-policy containersToHost
    firewall-cmd --permanent --policy containersToHost --add-ingress-zone containers
    firewall-cmd --permanent --policy containersToHost --add-egress-zone HOST
    firewall-cmd --permanent --policy containersToHost --set-target REJECT
    firewall-cmd --permanent --policy containersToHost --add-service dns

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


# create docker network
function createDockerNetwork() {
    local networkName=${1}

    docker network create --driver bridge --opt com.docker.network.bridge.name=${networkName} ${networkName}
}


# reset forward port rules for media server apps
# it will remove existing rules for the respective apps
# and add the rules again
function resetForwardPortRules() {
    local policy=${1}
    local plexPort=${2}
    local plexAddr=${3}
    local sonarrPort=${4}
    local sonarrAddr=${5}
    local nzbgetPort=${6}
    local nzbgetAddr=${7}
    
    # parse existing forward port rules 
    existingRules=$(firewall-cmd --policy ${policy} --list-forward-ports)

    for rule in ${existingRules}
    do
        IFS=':' read -r -a tmp1 <<< "${rule}"

        if (( ${#tmp1[@]} == 4 ));
        then
            IFS='=' read -r -a tmp2 <<< ${tmp1[0]}
            port=${tmp2[1]}

            IFS='=' read -r -a tmp2 <<< ${tmp1[1]}
            proto=${tmp2[1]}

            IFS='=' read -r -a tmp2 <<< ${tmp1[2]}
            toport=${tmp2[1]}

            IFS='=' read -r -a tmp2 <<< ${tmp1[3]}
            toaddr=${tmp2[1]}

            # find applications based on the expected port and remove the rule if found
            if (( $port == $plexPort )) || (( $port == $sonarrPort )) || (( $port == $nzbgetPort ));
            then
                removeForwardPortRule ${port} ${proto} ${toport} ${toaddr}
            fi
        fi
    done

    # add forward port rules
    addForwardPortRule ${policy} ${plexPort} "tcp" ${plexPort} ${plexAddr}
    addForwardPortRule ${policy} ${plexPort} "udp" ${plexPort} ${plexAddr}
    addForwardPortRule ${policy} ${sonarrPort} "tcp" ${sonarrPort} ${sonarrAddr}
    addForwardPortRule ${policy} ${nzbgetPort} "tcp" ${nzbgetPort} ${nzbgetAddr}

    firewall-cmd --reload
}
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

    firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client
    firewall-cmd --permanent --zone=public --remove-service=ssh
    firewall-cmd --permanent --zone=public --add-port=${sshPort}/tcp
    firewall-cmd --permanent --zone=public --add-interface eth0

    ## Firewall design:
    # Utilise built in public and trusted zones. Create a zone a zone specifically for containers. Zones are to be used for restricting access e.g. IP allowed listing.
    # Policies are used to bind forward port rules to.
    # Policies are then bound to the respective zones. This is mostly applicable when you want to restrict access to specific ports to specific IPs.
    
    firewall-cmd --permanent --new-zone containers
    firewall-cmd --permanent --zone=containers --set-target=ACCEPT

    firewall-cmd --permanent --new-policy containersToWorld
    firewall-cmd --permanent --policy containersToWorld --add-ingress-zone containers
    firewall-cmd --permanent --policy containersToWorld --add-egress-zone ANY
    firewall-cmd --permanent --policy containersToWorld --add-masquerade
    firewall-cmd --permanent --policy containersToWorld --add-rich-rule='rule service name="ftp" reject'

    firewall-cmd --permanent --new-policy inbound
    firewall-cmd --permanent --policy inbound --add-ingress-zone public
    firewall-cmd --permanent --policy inbound --add-ingress-zone trusted
    firewall-cmd --permanent --policy inbound --add-egress-zone ANY

    firewall-cmd --permanent --new-policy restrInbound
    firewall-cmd --permanent --policy restrInbound --add-ingress-zone trusted
    firewall-cmd --permanent --policy restrInbound --add-egress-zone ANY

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


function removeForwardPortRule() {
    local policy=${1}
    local port=${2}
    local proto=${3}
    local toport=${4}
    local toaddr=${5}

    firewall-cmd --permanent --policy ${policy} --remove-forward-port=port=${port}:proto=${proto}:toport=${toport}:toaddr=${toaddr}
}


function addForwardPortRule() {
    local policy=${1}
    local port=${2}
    local proto=${3}
    local toport=${4}
    local toaddr=${5}

    firewall-cmd --permanent --policy ${policy} --add-forward-port=port=${port}:proto=${proto}:toport=${toport}:toaddr=${toaddr}
}


# it will remove existing rules for the given policy & port
# and add the rules again with the provided ip address
function resetForwardPortRule() {
    local policy=${1}
    local port=${2}
    local toaddr=${3}
    local proto=${4}
    local toPort=${5}

    # parse existing forward port rules 
    # Note, this is only searching on forward port rules defined in policies ... 
    # when there is a generic get all forward port rules command, consider using it instead
    existingRules=$(firewall-cmd --policy ${policy} --list-forward-ports)

    for rule in ${existingRules}
    do
        IFS=':' read -r -a tmp1 <<< "${rule}"

        if (( ${#tmp1[@]} == 4 ));
        then
            IFS='=' read -r -a tmp2 <<< ${tmp1[0]}
            rulePort=${tmp2[1]}

            IFS='=' read -r -a tmp2 <<< ${tmp1[1]}
            ruleProto=${tmp2[1]}

            IFS='=' read -r -a tmp2 <<< ${tmp1[2]}
            ruleToport=${tmp2[1]}

            IFS='=' read -r -a tmp2 <<< ${tmp1[3]}
            ruleToaddr=${tmp2[1]}

            # remove the rule if the port and protocol match
            if (( ${port} == ${rulePort} )) && [[ ${proto} == ${ruleProto} ]];
            then
                removeForwardPortRule ${policy} ${rulePort} ${ruleProto} ${ruleToport} ${ruleToaddr}
            fi
        fi
    done

    if ! [[ ${toPort} =~ [[:digit:]]+ ]]; 
    then
        addForwardPortRule ${policy} ${port} ${proto} ${port} ${toaddr}
    else
        addForwardPortRule ${policy} ${port} ${proto} ${toPort} ${toaddr}
    fi

    firewall-cmd --reload
}


function getContainerIPAddress() {
    local ipAddress=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${1})
    echo ${ipAddress}
}


# add to IP allowed list
function addIPToZone() {
    local zone=${1}
    local ipAddr=${2}

    firewall-cmd --permanent --zone=${zone} --add-source=${ipAddr}/32
    firewall-cmd --reload
}

#!/bin/bash

# $1: service name
# This script is only for Debian distribution.

#DOCKER_CONFIG_FILE=/etc/sysconfig/docker
#SRV_POSTFIX=".service.consul"
unset dns_ip

OPTION_IP="-i"
OPTION_PORT="-p"

RESOLVING_TYPE_URL="url"
RESOLVING_TYPE_IP="ip"
RESOLVING_TYPE_PORT="port"
resolving_type=$RESOLVING_TYPE_URL

function func_usage(){
    echo "srv_resolver.sh [OPTION]"
    echo ""
    echo "OPTION"
    echo " $OPTION_IP means ip i.e., it returns the service ip address"
    echo " $OPTION_PORT means port i.e., it returns the service port number"
    exit
}

function func_parse_args(){
   local argp=0
   local argv=("$@")
   local argn=${#argv[@]}
   local unset remained_args

   while true; do
       ((remained_args=argn-argp))
       if [ $remained_args -eq 1 ] && [[ ${argv[argp]} == $OPTION_IP ]]; then
           resolving_type=$RESOLVING_TYPE_IP
           ((argp++))
           break
       elif [ $remained_args -eq 1 ] && [[ ${argv[argp]} == $OPTION_PORT ]]; then
           resolving_type=$RESOLVING_TYPE_PORT
           ((argp++))
           break
       else
           func_usage
       fi
       break
   done
}


# TODO: implement it. For now, use docker bridge ip as dns ip
function func_setup_dns(){
	local docker_bridge_ip=$(ip addr show docker0 | awk '/inet / {print $2}' | cut -d/ -f1)
	dns_ip=$docker_bridge_ip
}

function func_check_dep(){
	if [ -z $(which dig) ]; then
		sudo apt-get -y install dnsutils
	fi
}

# $1: service pretty name
function func_resolve_srv(){
	local srv_name=$1
	local dig_result=$(dig @$dns_ip $srv_name SRV )
	local srv_count=$(echo "$dig_result" | grep -E "^$srv_name.*SRV" | wc -l)
	if [ $srv_count -lt 1 ]; then
		return
	fi
	local unset srv_index
	local random=$RANDOM
	((srv_index=random%srv_count))
	local srv_fqdn=$(echo "$dig_result" | grep -E "^$srv_name.*SRV" | tail -n 1 | awk '{print $8}')
	local srv_port=$(echo "$dig_result" | grep -E "^$srv_name.*SRV" | tail -n 1 | awk '{print $7}')
	local srv_ip=$(echo "$dig_result" | grep -E "^$srv_fqdn" | awk '{print $5}')

	echo "$srv_ip:$srv_port"
}

argv=($@)
echo $@
func_parse_args ${argv[@]}
func_setup_dns
func_check_dep
func_resolve_srv $1

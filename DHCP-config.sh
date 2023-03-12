#!/bin/bash

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
#get system information
cat /proc/version |read sys_info
VerifyString=debian

if [[$sys_info =~ $VerifyString ]]
than
	echo "instaling packages"
else
	echo "Sorry This script only work on Debian" 1>&2 && exit 1
fi

#install packages		
apt update && apt install isc-dhcp-server

# enable Forward
echo "Sorry this scipt dosn't support ipv6"
net.ipv4.ip_forward=1
#net.ipv6.ip_forward=1

clear


function expectGenerate(){
## Function section
echo "====================="

echo "Config files"
echo "Folliw the guide to complete the config"

echo "====================="

echo "Which interface you want to provie service,one interface only\n"
read interface


}

#!/bin/bash
#check the user
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#get system information
cat /proc/version |read sys_info
VerifyString=debian

#Identify System
if [[$sys_info =~ $VerifyString ]];then
	echo "instaling packages"
else
	echo "Sorry This script only work on Debian" 1>&2 && exit 1
fi

if [ ! -d "/etc/default/isc-dhcp-server" ]; then #verify if dhcp server has been installed
   installDhcpServer
   expectGenerate
   configGenerate
   changeInterface
else
echo "isc-dhcp-server installed skip install"
   expectGenerate
   configGenerate
   changeInterface
fi



# Functions Sections
function installDhcpServer() {
#install packages		
apt update && apt install isc-dhcp-server

# enable Forward
echo "Enabling IPV4 forward"
systctl net.ipv4.ip_forward=1
#net.ipv6.ip_forward=1
clear
}
function expectGenerate(){
## Function section
echo "====================="
echo "Config files"
echo "Folliw the guide to complete the config"
echo "====================="

echo "Which interface(Port) you want to provie service,one interface only\n"
read interfac

echo "import subnet range eg.192.168.1.0:"
read subNet
echo "import net mask:"
read netMask
echo "Import Router:"
read Router
echo "Import DNS server address:"
read nameServer
read -p "Import start range:" startRange
read -p "Import end range:" endRange
read -p "Import domain search :" domainSearch
}


<<BLOCK
example Config
subnet 192.168.10.0 netmask 255.255.255.0 {
option routers 192.168.10.1;
option subnet-mask 255.255.255.0;
option domain-search “tecmint.lan”;
option domain-name-servers 192.168.10.1;
range 192.168.10.10 192.168.10.100;
range 192.168.10.110 192.168.10.200;
}
BLOCK

function configGenerate(){
echo   "subnet $subNet netmask $netMask {" >> /tmp/DHCP-exp
echo   "option routers $Router;" >> /tmp/DHCP-exp
echo   "option subnet-mask $netMask;" >> /tmp/DHCP-exp
echo   "option domain-search “$domainSearch”;" >> /tmp/DHCP-exp
echo   "option domain-name-servers $nameServer;" >> /tmp/DHCP-exp
echo   "range $startRange $endRange;" >> /tmp/DHCP-exp
echo "Config overview\n"
cat /tmp/DHCP-exp
read -p "Do you want to apply this config[Y/n]" ApplyStatus
if [$ApplyStatus -ne n];then
   cat /tmp/DHCP-exp >> /etc/default/isc-dhcp-server
else
   echo "Not apply"
fi
}


function changeInterface(){
   echo "currect config"
   grep "INTERFACES" /etc/default/isc-dhcp-server
   read -p "DO you want to change it[y/N]" intfChoice
   if [$intfChoice -ne y ];then
   echo "No changes"
   else
   sed -i "s/^.*INTERFACESv4.*$/INTERFACESv4=“$interface”/" /etc/default/isc-dhcp-server
   echo "Complet"
   fi   
}
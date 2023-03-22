#!/bin/bash

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

echo -e "Which interface(Port) you want to provie service,one interface only eg.eth0\n"
read interface

echo "import subnet range eg.192.168.1.0:"
read subNet
echo "import net mask eg.255.255.255.0:"
read netMask
echo "Import Router:"
read Router
echo "Import DNS server address:"
read nameServer
read -p "Import start range eg.192.168.1.100:" startRange
read -p "Import end range eg.192.168.1.200:" endRange
read -p "Import domain search :" domainSearch
}


<<BLOCK
example Config
subnet 192.168.10.0 netmask 255.255.255.0 {
option routers 192.168.10.1;
option subnet-mask 255.255.255.0;
option domain-search "tecmint.lan";
option domain-name-servers 192.168.10.1;
range 192.168.10.10 192.168.10.100;
range 192.168.10.110 192.168.10.200;
}
BLOCK

function configGenerate(){
echo   "subnet $subNet netmask $netMask {" >> /tmp/DHCP-exp
echo   " option routers $Router;" >> /tmp/DHCP-exp
echo   " option subnet-mask $netMask;" >> /tmp/DHCP-exp
echo   " option domain-search \"$domainSearch\";" >> /tmp/DHCP-exp
echo   " option domain-name-servers $nameServer;" >> /tmp/DHCP-exp
echo   " range $startRange $endRange;" >> /tmp/DHCP-exp
echo   "}" >> /tmp/DHCP-exp
echo -e "Config overview\n"
echo -e "==================\n"
cat /tmp/DHCP-exp
echo -e "==================\n"
echo "You may need to manualy change the default settings in config file"
echo "=============="
read -p "Do you want to apply this config[Y/n]" ApplyStatus
case $ApplyStatus in
   [yY])
      cat /tmp/DHCP-exp >> /etc/dhcp/dhcpd.conf
      rm /tmp/DHCP-exp;;
   *)
   echo "Not apply"
   rm /tmp/DHCP-exp;;
esac
}


function changeInterface(){
   echo "currect config"
   echo $(grep "INTERFACES" /etc/default/isc-dhcp-server)
   read -p "DO you want to change it[y/N]" intfChoice
   case $intfChoice in
      [yY]* )
      sed -i "s/^.*INTERFACESv4.*$/INTERFACESv4=\"$interface\"/" /etc/default/isc-dhcp-server
      sed -i "s/^.*INTERFACESv6.*$/INTERFACESv6=\"$interface\"/" /etc/default/isc-dhcp-server
      echo "Complet";;
      * )
      echo "No changes"
   esac 
}

# Program Start
#check the user ID
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#get system information
sys_info=$(cat /proc/version|grep debian)
VerifyString=debian

#Identify System
if [[ $sys_info =~ $VerifyString ]];then
	echo "instaling packages"
else
	echo "Sorry This script only work on Debian" 1>&2 && exit 1
fi



BeforeInstallWorning=understand
echo "Before you run this, make SHURE you have configed a static IP address On this Server"
read -p "please retype [$BeforeInstallWorning]" InstallWorning
if [$BeforeInstallWorning -ne $InstallWorning];then
   echo "Please maky shure you have a static IP" 1>&2
   exit 1
fi

# Auto detact is the server is installed add process
if [ ! -f "/etc/default/isc-dhcp-server" ]; then #verify if dhcp server has been installed
   installDhcpServer
   expectGenerate
   configGenerate
   changeInterface
   systemctl restart isc-dhcp-server
else
echo -p "=========\nisc-dhcp-server installed skip install\n========"
   expectGenerate
   configGenerate
   changeInterface
   systemctl restart isc-dhcp-server
fi
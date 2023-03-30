#!/bin/bash

#Identify UID
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


#GetSystemDistributor
Description=$(lsb_release -si)


#get IscDhcpServer status
IscStatus=$(systemctl is-active isc-dhcp-server)
if [ "$IscStatus" = "activate" ]; then
  IscStatus_color="\033[32m"  # Green
else
  IscStatus_color="\033[31m"  # Red
fi


#Check if package is installed
if dpkg -s isc-dhcp-server &> /dev/null; then
  InstallStatus="installed"
else
  InstallStatus="not installed"
fi

if [ "$InstallStatus" = "installed" ]; then
  IscInstall_color="\033[32m"  # Green
else
  IscInstall_color="\033[31m"  # Red
fi

# Functions Sections

#check if system is Debian-based
function CheckDescription(){
    if [ $Description != "Debian" ] && [ $Description != "Ubuntu" ];then
    echo "Sorry this script only work on Debian Descriptions" 1>&2
    exit 1
    fi
}

#Get Config Info
function expectGenerate(){
echo "====================="
echo "Folliw the guide to complete the config"
echo "====================="

echo -e "Which interface(Port) you want to provie service,one interface only eg.eth0\n"
read interface

echo "import subnet range eg.192.168.1.0:"
read subNet
echo "import net mask eg.255.255.255.0:"
read netMask
echo "Import Gateway:"
read Router
echo "Import DNS server address:"
read nameServer
read -p "Import start range eg.192.168.1.100:" startRange
read -p "Import end range eg.192.168.1.200:" endRange
read -p "Import domain search :" domainSearch
}


#Generage COnfig File
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


#Change Service Interface
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


#Menu set
function Menu(){
    echo -e "========SysInfo==========\n"
    echo -e "Description : \033[1;36m[$Description]\033[0m"
    echo -e "ISC-dhcp-server install status: ${IscStatus_color}[$IscStatus]\033[0m"
    echo -e "isc-dhcp-server status: ${IscInstall_color}[$IscStatus]\033[0m"
    echo -e "\n=========================\n"
    echo "1) Install isc-dhcp-server"
    echo "2) Activate Service"
    echo "3) Deactivate Service"
    echo "4) Enable Forwarding function(Ipv4)"
    echo "5) Disable IPtables"
    echo "6) Config DHCP Server"
    echo "7) Change Service Interface"
    echo "0) Exit Menu"
    echo -e "\n==============================="
    echo "please enter your choise:"
    read input
    case $input in
    1)
        # Install isc-dhcp-server
        apt-get update
        apt-get install isc-dhcp-server
        ;;
    2)
        # Activate Service
        systemctl start isc-dhcp-server
        ;;
    3)
        # Deactivate Service
        systemctl stop isc-dhcp-server
        ;;
    4)
        # Enable Forwarding function(Ipv4)
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        sysctl -p
        ;;
    5)
        # Disable IPtables
        systemctl stop iptables
        systemctl disable iptables
        ;;
    6)
        # Config DHCP Server
        expectGenerate
        configGenerate
        nano /etc/dhcp/dhcpd.conf
        systemctl restart isc-dhcp-server
        ;;
    7)
        changeInterface
        ;;
    0)
        # Exit Menu
        echo "Goodbye!"
        exit
        ;;
    *)
        echo "Invalid choice, please enter a valid choice."
        ;;
esac
read -p "Press Enter to continue..."
clear
}
Menu
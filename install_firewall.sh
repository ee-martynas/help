#!/bin/bash

#
# Author: Martin Ott 15.05.2018
#
# Initial firewall script intended to be used with fresh Linux installations
# After first run the install script will be removed leaving only
# with /etc/firewall.sh file which can then be manually edited.
#
#
# Usage:
# First time use
#	1) wget <script_url>
#	2) sh <script_name>
#
# Afterwards
#	1) sh /etc/firewall.sh
#

# Colors used when printing out messages.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

# Restore console color.
NC='\033[0m'		# Default color

# Checks if the queried package is installed. Prints out command exit code. 0 if package is installed.
check_package(){
	dpkg-query -W --showformat='${Status}\n' $1 2>/dev/null | grep "install ok installed" >/dev/null
	echo $?
}

# Checks if required packages are installed. Installs them if missing.
check_dependencies(){
	# With debconf should come debconf-set-selections.
	if [ $(check_package debconf) -ne 0 ]; then
		install_package debconf
	fi

	# iptables-persistent is used to save the firewall rules. Otherwise all the rules will be lost after restart.
	# debconf-set-selections is used to eliminate the need to interact when installing iptables-persistent.
	if [ $(check_package iptables-persistent) -ne 0 ]; then
		echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
		echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
		install_package iptables-persistent
	fi
}

# Installs the specified package. After installation re-checks and exit-s the script if installation did not work.
install_package(){
	echo "${YELLOW}Package $1 not installed. Installing it now.${NC}"
	sudo apt-get install -y $1
	
	if [ $(check_package $1) -ne 0 ]; then
		echo "${RED}Failed to install $1.${NC}"
		exit 1
	else
		echo "${GREEN}Package $1 installed${NC}"
	fi
}

# Checks for dependencies, then builds and executes the firewall script.
install_firewall(){
	check_dependencies
	echo "${GREEN}Dependencies are OK${NC}"
	cat > /etc/firewall.sh <<'EOL'
#!/bin/bash

# Variables
IP_4=/sbin/iptables
IP_6=/sbin/ip6tables


##################################
########### IPv4 rules ###########
##################################

echo "Flushing old IPv4 firewall rules ..."
$IP_4 -F
$IP_4 -P INPUT DROP

echo "Setting up IPv4 firewall rules ..."
echo "  Local ..."
$IP_4 -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IP_4 -A INPUT -i lo -j ACCEPT

echo "  Management ..."
$IP_4 -A INPUT -s 0.0.0.0/0 -j ACCEPT		# Remove this rule if you have your own IP in place

echo "  Miscellaneous ..."
$IP_4 -A INPUT -m limit --limit 1/min -j LOG --log-prefix "IPTables4_INPUT_Drop: " --log-level 4
$IP_4 -A OUTPUT -m limit --limit 1/min -j LOG --log-prefix "IPTables4_OUTPUT_All: " --log-level 4
$IP_4 -A INPUT -p ICMP -j ACCEPT

echo "Saving IPv4 rules ..."
$IP_4-save > /etc/iptables/rules.v4

##################################
########### IPv6 rules ###########
##################################

echo "Flushing old IPv6 firewall rules ..."
$IP_6 -F
$IP_6 -P INPUT DROP

echo "Setting up IPv6 firewall rules ..."
echo "  Local ..."
$IP_6 -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IP_6 -A INPUT -i lo -j ACCEPT

echo "  Miscellaneous ..."
$IP_6 -A INPUT -m limit --limit 1/min -j LOG --log-prefix "IPTables6_INPUT_Drop: " --log-level 4
$IP_6 -A OUTPUT -m limit --limit 1/min -j LOG --log-prefix "IPTables6_OUTPUT_All: " --log-level 4
$IP_6 -A INPUT -p IPv6-ICMP -j ACCEPT

echo "Saving IPv6 rules ..."
$IP_6-save > /etc/iptables/rules.v6

EOL
	echo "${GREEN}Firewall script created${NC}"
	sudo sh /etc/firewall.sh
	echo "${GREEN}FIREWALL RULES ACTIVATED${NC}"
	# Removing the firewall build script as it isnt needed any more.
	rm $0
}

# Check if lsb_release is installed as it is needed to understand which distro are we using.
if [ $(check_package lsb-release) -ne 0 ]; then
        install_package lsb-release
fi

distro=`lsb_release -is`

# Main place based on what the script will be executed.
# If we do not get a mach to your distro then nothing will be done.
case $distro in
	Debian|Ubuntu)
		# Tested on:
		#   Debian 7 and 9
		#   Ubuntu 12.04, 14.04 and 16.04
		sudo apt-get update
		install_firewall
		;;
	*)
		echo "Currently the script will not continue with $distro as it is not tested"
		;;
esac


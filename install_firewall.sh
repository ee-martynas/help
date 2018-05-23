#!/bin/bash

###########################################
###	State: Unstable/Not working	###
###########################################
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

# Not needed but good to have extra noise
#release=`lsb_release -rs`
#codename=`lsb_release -cs`

GREEN='\033[0;32m'	# Text in green
RED='\033[0;31m'	# Text in red
NC='\033[0m'		# Default color

distro=`lsb_release -is`
package_check=$(dpkg-query -W --showformat='${Status}\n' iptables-persistent 2>/dev/null | grep "install ok installed")
utils_check=$(dpkg-query -W --showformat='${Status}\n' debconf-utils 2>/dev/null | grep "install ok installed")

check_dependencies(){
	if [ -z "$utils_check" ]; then
		install_package debconf-utils
	fi

	if [ -z "$package_check" ]; then
		echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
		echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
		install_package iptables-persistent
	fi
}

install_package(){
	sudo apt-get install -y $1
	echo "${GREEN}Package $1 installed${NC}"
}

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
$IP_4 -A INPUT -s 0.0.0.0/0 -j ACCEPT       # Remove this rule if you have your own ip in place

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
	rm $0
}

case $distro in
	Debian)
		;;
	Ubuntu)
		install_firewall
		;;
	*)
		echo "Currently the script will not continue with $distro as it is not tested"
		;;
esac


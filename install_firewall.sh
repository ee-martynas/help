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

distro=`lsb_release -is`
package_check=$(dpkg-query -W --showformat='${Status}\n' iptables-persistent|grep "install ok installed")


check_dependencies(){
	if [ "" != "$package_check" ]; then
		install_package iptables-persistent
	fi
}

install_package(){
	sudo apt-get install $1
	# check if package is now installed. If not then exit
}

install_firewall(){
	check_dependencies
	echo "firewall-script-rules" > /etc/firewall.sh
	sudo sh /etc/firewall.sh
	# Install script self remove
}

case $distro in
	Debian)
		;;
	Ubuntu)
		;;
	*)
		;;
esac


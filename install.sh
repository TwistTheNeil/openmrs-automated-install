#!/bin/bash
#------------------------------------------------------------------------------
# Add stuff here later
#------------------------------------------------------------------------------

# Variables we would find important
PACMAN=""		# Package manager
UPDATE="update"		# Package manager option to update system
UPGRADE="upgrade"	# Package manager option to upgrade system
INSTALL_PATH=""		# Installation path

# Dependencies
#TODO Add real dependencies..
DEPENDENCIES="git eclipse"

# Find out what system we're working with
pretty_name=$(cat /etc/os-release | grep PRETTY_NAME | sed -e 's/.*="\(.*\)"/\1/')
release_id=$(cat /etc/os-release | grep ^ID | sed -e 's/.*=\(.*\)/\1/')
echo "System details:"
echo -e "\tOS: $pretty_name"

# Init package manager details
if [ "x$release_id" == "xdebian" ]; then
	PACMAN="apt"
elif [ "x$relese_id" == "xfedora" ]; then
	PACMAN="yum"
fi
echo -e "\tUsing package manager: $PACMAN"

#TODO Add the real stuff
# tc_security=no sudo sed -i 's/TOMCAT\([0-9]*\)_SECURITY.*/TOMCAT\1_SECURITY=no/' /etc/init.d/tomcat8

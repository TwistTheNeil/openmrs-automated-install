#!/bin/bash
#------------------------------------------------------------------------------
# Add stuff here later
#------------------------------------------------------------------------------

# Variables we would find important
PACMAN=""		# Package manager
UPDATE="update"		# Package manager option to update system
UPGRADE="upgrade"	# Package manager option to upgrade system
INSTALL_PATH=""		# Installation path

DEPENDENCIES="build-essential git openjdk-7-jdk tomcat7 tomcat7-admin mysql-server"

# Find out what system we're working with
pretty_name=$(cat /etc/os-release | grep PRETTY_NAME | sed -e 's/.*="\(.*\)"/\1/')
release_id=$(cat /etc/os-release | grep ^ID | sed -e 's/.*=\(.*\)/\1/')
echo "System details:"
echo -e "\tOS: $pretty_name"

# Init package manager details
if [ "x$release_id" == "xdebian" ]; then
	PACMAN="apt-get"
elif [ "x$relese_id" == "xfedora" ]; then
	PACMAN="yum"
fi
echo -e "\tUsing package manager: $PACMAN"

# Update repositories
sudo $PACMAN $UPDATE
sudo $PACMAN $UPGRADE

# Install dependencies
for dep in "$DEPENDENCIES"; do
	sudo $PACMAN install $dep
done

# Notify user about the need for a password change
less notes/tomcat-user

# Copy template tomcat users file to /etc/tomcatX/ and add permissions
sudo cp templates/tomcat-users.xml /etc/tomcat7/
sudo chmod 640 /etc/tomcat7/tomcat-users.xml

# Make sure tomcat7_security=no
sudo sed -i 's/TOMCAT\([0-9]*\)_SECURITY.*/TOMCAT\1_SECURITY=no/' /etc/init.d/tomcat7

# stop/start tomcat
sudo service tomcat7 start

# Notify the user about deploying OpenMRS
less notes/deploy 

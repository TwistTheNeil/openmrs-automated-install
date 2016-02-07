#!/bin/bash
#------------------------------------------------------------------------------
# Add stuff here later
#------------------------------------------------------------------------------

# Variables we would find important
PACMAN=""		# Package manager
UPDATE="update"		# Package manager option to update system
UPGRADE="upgrade"	# Package manager option to upgrade system
INSTALL_PATH=""		# Installation path

DEPENDENCIES="build-essential git openjdk-7-jdk openjdk-7-dbg openjdk-7-demo openjdk-7-doc openjdk-7-jre  tomcat7 tomcat7-admin tomcat7-common tomcat7-docs tomcat7-examples tomcat7-user mysql-server curl"

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

# Tomcat was started, we need to stop it for configuration
sudo service tomcat7 stop

# Notify user about the need for a password change
less notes/tomcat-user

# Copy template tomcat users file to /etc/tomcatX/ and add permissions
sudo cp templates/tomcat-users.xml /etc/tomcat7/
sudo chmod 640 /etc/tomcat7/tomcat-users.xml

# Create OpenMRS application data directory and make it writable by Tomcat
sudo mkdir /var/lib/OpenMRS
sudo chown -R tomcat7 /var/lib/OpenMRS
sudo chgrp -R tomcat7 /var/lib/OpenMRS

# Make sure tomcat7_security=no
sudo sed -i 's/^TOMCAT\([0-9]*\)_SECURITY.*/TOMCAT\1_SECURITY=no/' /etc/init.d/tomcat7

# stop/start tomcat
sudo service tomcat7 start

# Notify the user about deploying OpenMRS
less notes/deploy 

# Download openmrs.war (This scrapes the openmrs website and this command may
# break at any point in time. Sorry about that..)
wget $(curl -s  http://openmrs.org/download/ | grep sourceforge | grep openmrs.war | head -n 1 | sed -e 's/.*a\shref=\"\(.*\)\/download\"\s.*/\1/')

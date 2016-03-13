#!/bin/bash
#------------------------------------------------------------------------------
# Usage: ./install.sh
# Purpose: Automate the installation process on debian and perhaps more
#	   distributions in the future since
#------------------------------------------------------------------------------

# Check if we have root
if [ "$(id -u)" != "0" ]; then
	echo "Need root for this."
	exit 2
fi

# Variables we would find important
PACMAN=""		# Package manager
UPDATE="update"		# Package manager option to update system
UPGRADE="upgrade"	# Package manager option to upgrade system
pretty_name=""
release_id=""
DEPENDENCIES=""
TOMCAT=""
DEPENDENCIES=""

# Find out what system we're working with
if [ -e /etc/os-release ]; then
	pretty_name=$(cat /etc/os-release | grep PRETTY_NAME | sed -e 's/.*="\(.*\)"/\1/')
	release_id=$(cat /etc/os-release | grep ^ID= | sed -e 's/.*=\(.*\)/\1/')
else
	release_id=$(lsb_release -i | sed -e 's/.*:\s\(.*\)/\1/')
	pretty_name="$release_id"
fi

echo "System details:"
echo -e "\tOS: $pretty_name (ID=$release_id)"

# Init package manager details
if [ "x${release_id,,}" == "xdebian" ] || [ "x${release_id,,}" == "xubuntu" ]; then
	DEPENDENCIES="build-essential git openjdk-7* tomcat7 tomcat7-admin tomcat7-common mysql-server curl unzip"
	PACMAN="apt"
	TOMCAT="tomcat7"
elif [ "x${release_id,,}" == "xfedora" ]; then
	DEPENDENCIES="make unzip automake gcc gcc-c++ kernel-devel git java-1.8.0-openjdk tomcat tomcat-webapps.noarch tomcat-admin-webapps.noarch mysql-server curl"
	PACMAN="dnf"
	TOMCAT="tomcat"
else
	echo "Oops, this script doesn't support your system. Sorry about that"
	echo "However, you can contribute to the repository and help us support it!"
	exit 99
fi
echo -e "\tUsing package manager: $PACMAN"

# Update repositories
$PACMAN $UPDATE
$PACMAN $UPGRADE

# Install dependencies
for dep in "$DEPENDENCIES"; do
	sudo $PACMAN install $dep
done

# Tomcat was started, we need to stop it for configuration
service $TOMCAT stop

# Notify user about the need for a password change
less notes/tomcat-user-linux

# Copy template tomcat users file to /etc/tomcatX/ and fix permissions
cp templates/tomcat-users.xml /etc/$TOMCAT/
chmod 640 /etc/$TOMCAT/tomcat-users.xml

# Create OpenMRS application data directory and make it writable by Tomcat
mkdir /var/lib/OpenMRS
chown -R $TOMCAT /var/lib/OpenMRS
chgrp -R $TOMCAT /var/lib/OpenMRS

# Make sure we aren't using java_security by setting tomcat7_security=no
sed -i 's/^TOMCAT\([0-9]*\)_SECURITY.*/TOMCAT\1_SECURITY=no/' /etc/init.d/$TOMCAT

# Reload daemon because of the changes to init.d
systemctl daemon-reload

# start tomcat
service $TOMCAT start

# Notify the user about deploying OpenMRS
less notes/deploy-linux

# Download openmrs.war (This scrapes the openmrs website and this command may
# break at any point in time. Sorry about that..)
# I specify it to download to /dev/shm/
wget $(curl -s  http://openmrs.org/download/ | grep sourceforge | grep openmrs.war | head -n 1 | sed -e 's/.*a\shref=\"\(.*\)\/download\"\s.*/\1/') -P /dev/shm/

# Attempt to deploy openmrs
mkdir /var/lib/$TOMCAT/webapps/openmrs
cd /var/lib/$TOMCAT/webapps/openmrs
mv /dev/shm/openmrs.war .
unzip openmrs.war

# Wait a few seconds for tomcat to discover it
sleep 3

# Show closing note
less notes/closing-linux

# Fire up the webapp
firefox localhost:8080/openmrs &

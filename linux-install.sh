#!/bin/bash
#------------------------------------------------------------------------------
# Usage (as root): ./linux-install.sh
#
# Purpose: Automate the installation process on debian and perhaps more
#	   distributions in the future since
#
# Info: This script installs all the dependencies required to run an instance of
#	OpenMRS standalone on Debian, Ubuntu, Debian derived distributions, and
#	Fedora. After attempting to deploy OpenMRS, it will present a firefox
#	instance loaded with a url which points to OpenMRS which the user will
#	have to manually configure according to their liking.
#
# Note: This is NOT a setup for the development environment, just the standalone
#	It takes Tomcat anywhere between 2-10 minutes to notice that openMRS
#	has been deployed.
#
# Demonstration: https://www.youtube.com/watch?v=o-78lKiN0eE
#------------------------------------------------------------------------------

# Check if we have root
if [ "$(id -u)" != "0" ]; then
	echo "Need root for this."
	exit 2
fi

# Variables we would find important
readonly GIT_REPO_DIR="$PWD"
PACMAN=""		# Package manager
UPDATE="update"		# Package manager option to update system
pretty_name=""
release_id=""
DEPENDENCIES=""
TOMCAT=""
INSTALL="install"

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

# Remove "" from release id getting default values in Centos
if [[ ${release_id:0:1} = \" ]] ; then
        centos_id=$(sed -e 's/^"//' -e 's/"$//' <<<"$release_id")
        release_id=$centos_id
fi

# Init package manager details
if [ "x${release_id,,}" == "xdebian" ] || [ "x${release_id,,}" == "xubuntu" ]; then
	DEPENDENCIES="build-essential git openjdk-7* tomcat7 tomcat7-admin tomcat7-common mysql-server curl unzip"
	PACMAN="apt"
	TOMCAT="tomcat7"
	UPDATE="update -y"
	INSTALL="install -y"
elif [ "x${release_id,,}" == "xfedora" ]; then
	DEPENDENCIES="make unzip automake gcc gcc-c++ kernel-devel git java-1.8.0-openjdk tomcat tomcat-webapps.noarch tomcat-admin-webapps.noarch mysql-server curl"
	PACMAN="dnf"
	TOMCAT="tomcat"
elif [ "x${release_id,,}" == "xcentos" ] ; then
	DEPENDENCIES="make unzip automake gcc gcc-c++ kernel-devel git java-1.8.0-openjdk tomcat tomcat-webapps.noarch tomcat-admin-webapps.noarch mariadb-server curl"
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

# Install dependencies
for dep in "$DEPENDENCIES"; do
	sudo $PACMAN $INSTALL $dep
done

# Tomcat was started, we need to stop it for configuration
systemctl stop $TOMCAT

# Notify user about the need for a password change
less "${GIT_REPO_DIR}/notes/tomcat-user-linux"

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
systemctl start $TOMCAT

# Notify the user about deploying OpenMRS
less "${GIT_REPO_DIR}/notes/deploy-linux"

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
less "${GIT_REPO_DIR}/notes/closing-linux"

# Fire up the webapp
[ $(which firefox) ] && firefox localhost:8080/openmrs &

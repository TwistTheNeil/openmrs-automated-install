#!/bin/bash
#------------------------------------------------------------------------------
# Usage: ./install.sh
# Purpose: Automate the installation process on debian and perhaps more
#	   distributions in the future since
#------------------------------------------------------------------------------

if [ "$(uname)" == "Darwin" ]; then
	DEPENDENCIES="git tomcat mysql curl"
	
	#Update Homebrew repositories
	brew update
	brew doctor
	brew upgrade
    
	#Install brew-cask in order to install java
	brew tap caskroom/cask
	brew install brew-cask
	brew cask install java

	# Install dependencies
        for dep in "$DEPENDENCIES"; do
        	brew install $dep
        done

	# Shutdown tomcat in case it is running
	/usr/local/Cellar/tomcat/*/libexec/bin/shutdown.sh &

	# Notify user about the need for a password change
        less notes/tomcat-user
	
	# Copy template tomcat users file to /etc/tomcatX/ and fix permissions
        cp templates/tomcat-users.xml /usr/local/Cellar/tomcat/*/libexec/conf/
        chmod 640 /usr/local/Cellar/tomcat/*/libexec/conf/tomcat-users.xml

	# Start tomcat
	/usr/local/Cellar/tomcat/*/libexec/bin/startup.sh &

	# Download openmrs.war (This scrapes the openmrs website and this command may
        # break at any point in time. Sorry about that..)
        # I specify it to download to /User/Downloads
        wget $(curl -s http://openmrs.org/download/ | grep sourceforge | grep openmrs.war | head -n 1 | awk -F'"' '{print $2}' | sed -e 's/\/download$//') -P ~/Downloads/

        # Attempt to deploy openmrs
        cd /usr/local/Cellar/tomcat/*/libexec/webapps/
	mkdir openmrs
        cd openmrs
        mv ~/Downloads/openmrs.war .
        unzip openmrs.war

        # Wait a few seconds for tomcat to discover it
        sleep 3

	# Open OpenMRS in Firefox
	/Applications/Firefox.app/Contents/MacOS/firefox http://localhost:8080/openmrs &

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform

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

	DEPENDENCIES="build-essential git openjdk-7* tomcat7 tomcat7-admin tomcat7-common  mysql-server curl"

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
		PACMAN="apt"
	elif [ "x${release_id,,}" == "xfedora" ]; then
		PACMAN="yum"
		echo "Needs testing on fedora. Sorry."
		exit 88
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
	service tomcat7 stop

	# Notify user about the need for a password change
	less notes/tomcat-user

	# Copy template tomcat users file to /etc/tomcatX/ and fix permissions
	cp templates/tomcat-users.xml /etc/tomcat7/
	chmod 640 /etc/tomcat7/tomcat-users.xml

	# Create OpenMRS application data directory and make it writable by Tomcat
	mkdir /var/lib/OpenMRS
	chown -R tomcat7 /var/lib/OpenMRS
	chgrp -R tomcat7 /var/lib/OpenMRS

	# Make sure we aren't using java_security by setting tomcat7_security=no
	sed -i 's/^TOMCAT\([0-9]*\)_SECURITY.*/TOMCAT\1_SECURITY=no/' /etc/init.d/tomcat7

	# Reload daemon because of the changes to init.d
	systemctl daemon-reload

	# start tomcat
	service tomcat7 start

	# Notify the user about deploying OpenMRS
	less notes/deploy 

	# Download openmrs.war (This scrapes the openmrs website and this command may
	# break at any point in time. Sorry about that..)
	# I specify it to download to /dev/shm/
	wget $(curl -s  http://openmrs.org/download/ | grep sourceforge | grep openmrs.war | head -n 1 | sed -e 's/.*a\shref=\"\(.*\)\/download\"\s.*/\1/') -P /dev/shm/

	# Attempt to deploy openmrs
	mkdir /var/lib/tomcat7/webapps/openmrs
	cd /var/lib/tomcat7/webapps/openmrs
	mv /dev/shm/openmrs.war .
	unzip openmrs.war

	# Wait a few seconds for tomcat to discover it
	sleep 3

	# Show closing note
	less notes/closing

	# Fire up the webapp
	firefox localhost:8080/openmrs &
fi

#!/bin/bash
#------------------------------------------------------------------------------
# Requirements: Homebrew
#
# Usage: ./mac-install.sh
# 
# Purpose: Automates installation of the standalone edition of OpenMRS on a Mac.
# 	   This is a version of the software that would be used by the average
#	   user who is interested in using OpenMRS.
#
# Info: The script downloads all of the dependencies that are required for
# 	OpenMRS using Homebrew.	After all of the dependencies have been
#	installed, the scripts sets up and starts Apache Tomcat. It then goes to
#	the website of OpenMRS, downloads the OpenMRS standalone version, and
#	places it in the Tomcat webapp directory. It then opens a FireFox
#	browser with the URL to the web application.
#
# Note: This is NOT a setup for the development environment, just the standalone
#	It takes Tomcat anywhere between 2-10 minutes to notice that openMRS
#	has been deployed.
#
# Demonstration: https://www.youtube.com/watch?v=o-78lKiN0eE
#------------------------------------------------------------------------------

if [ "$(uname)" == "Darwin" ]; then
	DEPENDENCIES="git tomcat mysql curl"
	
	#Update Homebrew repositories
	brew update
	brew doctor
	brew upgrade
    
	#Install brew-cask in order to install java
	brew tap caskroom/cask
	brew install brew-cask # install brew-cask since java is not directly supported by brew
	brew cask install java # install java

	# Install dependencies
        for dep in "$DEPENDENCIES"; do
        	brew install $dep
        done

	tomcat_version=$(brew info tomcat | grep 'stable' | sed 's/^.*tomcat: stable //; s/, devel.*$//')

	# Shutdown tomcat in case it is running
	/usr/local/Cellar/tomcat/$tomcat_version/libexec/bin/shutdown.sh &

	# Notify user about the need for a password change
        less notes/tomcat-user-mac
	
	# Copy template tomcat users file to /etc/tomcatX/ and fix permissions
        cp templates/tomcat-users.xml /usr/local/Cellar/tomcat/$tomcat_version/libexec/conf/
        chmod 640 /usr/local/Cellar/tomcat/$tomcat_version/libexec/conf/tomcat-users.xml

	# Start tomcat
	/usr/local/Cellar/tomcat/$tomcat_version/libexec/bin/startup.sh &

	# Notify the user about deploying OpenMRS
	less notes/deploy-mac
	
        # Older versions of OS X don't come with wget installed
        brew install wget
        
	# Download openmrs.war (This scrapes the openmrs website and this command may
        # break at any point in time. Sorry about that..)
        # I specify it to download to /User/Downloads
        wget $(curl -s http://openmrs.org/download/ | grep sourceforge | grep openmrs.war | head -n 1 | awk -F'"' '{print $2}' | sed -e 's/\/download$//') -P ~/Downloads/

        # Attempt to deploy openmrs using tomcat
        mkdir /usr/local/Cellar/tomcat/$tomcat_version/libexec/webapps/openmrs
	mv ~/Downloads/openmrs.war /usr/local/Cellar/tomcat/$tomcat_version/libexec/webapps/openmrs
	unzip /usr/local/Cellar/tomcat/$tomcat_version/libexec/webapps/openmrs/openmrs.war -d /usr/local/Cellar/tomcat/$tomcat_version/libexec/webapps/openmrs/

        # Wait a few seconds for tomcat to discover it
        sleep 3

	# Show closing note
	less notes/closing-mac

	# Open OpenMRS in Firefox
	/Applications/Firefox.app/Contents/MacOS/firefox http://localhost:8080/openmrs &
else # Don't do anything if the machine it is being run on is not a Mac
	echo "OS: $(uname)"
	echo "Make sure you're running the correct script!"
	exit 2
fi

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
else
	echo "OS: $(uname)"
	echo "Make sure you're running the correct script!"
	exit 2
fi

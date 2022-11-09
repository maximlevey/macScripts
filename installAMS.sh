#!/bin/bash

# .-.-.-..---..-..-..-..-.-.-.
# | | | || | | >  < | || | | |
# `-'-'-'`-^-''-'`-``-'`-'-'-'

#---Information---#

# installAMS.sh
# Install & Configure Lithnet Access Manager
# Created by Maxim Levey <github.com/maximlevey>
# Last Modified 10/11/2022

#---Variables---#

# Hardcoded values for serverName and registrationKey can be set below
# For Jamf deployments, set variables via "Parameter 4" and "Parameter 5"

serverAddress=""
registrationKey=""

#---Functions---#

# Create decaf function
# Function kills CAFPID (Caffeinate Process ID) if running

function decaf () {
	
	if [ ${CAFPID} ]; then
		/bin/echo ""
		/bin/echo "Decaffeinated"
		kill ${CAFPID}
	fi
}

#---Start Script---#

# Run function decaf on exit
	
trap decaf EXIT

# Check to see if a value was passed to parameter 4, if so, assign to serverAddress

if [[ "$4" != "" ]] && [[ "$serverAddress" == "" ]]
then
	serverAddress=$4
fi

# Check to see if a value was passed to parameter 5, if so, assign to registrationKey

if [[ "$5" != "" ]] && [[ "$registrationKey" == "" ]]
then
	registrationKey=$5
fi

# Check if device already Caffeinated, run if not

if /bin/ps auxww | grep -q "[c]affeinate"; then
	/bin/echo "Already caffeinated"
else
	/bin/echo "Caffeinating..."
	/usr/bin/caffeinate -dimsu &
	CAFPID=$!
fi

# Check device architecture and download correct agent

if [[ $(uname -m) == 'arm64' ]]; then 
	curl -fsSL https://packages.lithnet.io/macos/access-manager-agent/v2.0/arm64/stable -o /private/tmp/accessmanageragent.pkg
else
	curl -fsSL https://packages.lithnet.io/macos/access-manager-agent/v2.0/x64/stable -o /private/tmp/accessmanageragent.pkg
fi

# Install the agent

installer -pkg /private/tmp/accessmanageragent.pkg -target /

# Configure the agent 

/Library/Application\ Support/Lithnet/AccessManagerAgent/Core/Lithnet.AccessManager.Agent --server $serverAddress --registration-key $registrationKey

# Restart the agent

launchctl kickstart -k system/io.lithnet.accessmanager.agent

# Delete the installer

/bin/echo ""
/bin/echo "Removing Installers..."
/bin/rm /private/tmp/accessmanageragent.pkg
/bin/echo "Cleanup Complete"

# Print registration key and server address

/bin/echo ""
/bin/echo "Installation Complete!"
/bin/echo "Registration Key: $registrationKey"
/bin/echo "Server Address: $serverAddress"

exit 0

#---End Script---#

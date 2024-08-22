#!/bin/bash

#This is the begining of the script to inform user that the script has started
#printout to user on what the script is doing.
echo 'Greetings, User.
Checking for required programs'
echo ' '

#These colour codes to increase key command words' visibility
#colour codes assignment.
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BGRN='\033[1;32m'
BCYN='\033[1;36m'
CLR='\033[0m'

# Function to install NIPE, sshpass and geoip-bin
install_nipe() {
	sudo apt update
	echo "Cloning NIPE repository..."
	sudo git clone https://github.com/htrgouvea/nipe.git && cd nipe

	echo "Installing NIPE dependencies..."
	cpanm --installdeps .
	sudo cpan install Switch JSON LWP::UserAgent Config::Simple

	echo "Installing NIPE..."
	sudo perl nipe.pl install

	echo "NIPE installation complete."
}

install_sshpass() {
	sudo apt update
	sudo apt install sshpass
	echo "sshpass installation complete"
}

install_geoip() {
	sudo apt update
	sudo apt install geoip-bin
	echo "geoip-bin installation complete"
}

#This checks for nipe.
echo ' '
NPL=$(find ~ -name nipe.pl)
if [ -z $NPL ]
then 
	echo -e "Nipe NOT found! Installing Nipe"
	install_nipe
else
	echo -e "Nipe ${GRN}detected${CLR}."
fi 

#This checks for sshpass.
SSHP=$(ls /usr/bin | grep sshpass)
if [ -z $SSHP ]
then
	echo -e "sshpass NOT found! Installing sshpass"
	install_sshpass
else
	echo -e "sshpass ${GRN}detected${CLR}."
fi 

#This checks for geoip-bin.
GEOIP=$(find /usr/share -name 'geoip-bin')
if [ -z $GEOIP ]
then 
	echo -e "geoip-bin NOT found! Installing geoip-bin"
	install_geoip
else
	echo -e "geoip-bin ${GRN}detected${CLR}."
fi 
echo ' '

#Installation checks ends
#IP spoofing with NIPE
#confirm that the spoof is active.
echo ' '
echo 'Proceeding to spoof IP...'
cd ~/nipe
#nipe can only be executed from the nipe directory so the script must proceed to the specific directory/folder where nipe.pl is located
sudo perl nipe.pl restart
#Restarts function initiates the service into an active state regardless of nipe's status.

STAT=$(sudo perl nipe.pl status | grep -i true)
IP=$(sudo perl nipe.pl status | grep -i ip | awk '{print$3}')
#nipe status check.
if [ -z "$STAT" ]
#Double quotation marks were used to prevent the "'[] were use to prevent excessive arguments"
#Also preventserror arising from spaces in the output
then
	echo -e "Spoof ${RED}NOT${CLR} active!
Please check nipe installation and/or network connections and run this script again."
	exit

else
	echo -e "Spoof ${GRN}ACTIVE${CLR}. Masking your original IP Address."
	echo "Spoofed IP Address: $IP"
	geoiplookup "$IP"
	
fi
echo ' '

#The commands below communicates with the remote server.
#For the purposes of this script we shall assume that the remote server already has whois and nmap.

echo -e "Please enter ${YLW}remote${CLR} User login"
read REMLOG
echo -e "Please enter ${YLW}remote${CLR} IP"
read REMIP
echo -e "Please enter ${YLW}remote${CLR} User password"
read REMPW
echo -e "Please provide ${RED}TARGET${CLR} IP/Domain to scan"
read VIP
echo ' '

#Automated scanning and saving of logs into a file

#The command below provides the user input of remote server IP address entered earlier, country and uptime.
echo 'Connecting to Remote Server...'
IPTRUE=$(sshpass -p "$REMPW" ssh "$REMLOG@$REMIP" 'curl -s ifconfig.co')
echo "IP Address: $IPTRUE"
whois "$IPTRUE" | grep -i country | sort | uniq
UPT=$(sshpass -p "$REMPW" ssh "$REMLOG@$REMIP" 'uptime')
echo "Uptime: $UPT"
echo ' '

#Remote server will scan the target for the user.
#whois is scanned first, followed by nmap.
#The respective scan outputs will be saved into seperate files
echo ' '
echo 'Scanning Target...'
echo "Saving whois data into $VIP-whois"
sshpass -p "$REMPW" ssh "$REMLOG@$REMIP" "whois $VIP >> $VIP-whois"

echo "Saving nmap data into $VIP-nmap"
sshpass -p "$REMPW" ssh "$REMLOG@$REMIP" "nmap $VIP -Pn -sV -oN $VIP-nmap"
echo ' '

#The command below copy the scan results from the remote system to the local sytem and delete any previous files created.
echo 'Transferring scan and extracted results from remote system...'
sshpass -p "$REMPW" scp "$REMLOG@$REMIP":~/"$VIP-nmap" /home/kali
sshpass -p "$REMPW" scp "$REMLOG@$REMIP":~/"$VIP-whois" /home/kali
sshpass -p "$REMPW" ssh "$REMLOG@$REMIP" "rm $VIP*"
echo 'Transfer has been completed..'
echo ' '

#The command below inform user that scanning is complete and provide file path of the logs.
#Creation of directory 'NRW' and its sub-directories for ease of collection of data withinn an unified folder.
echo -e "${BGRN}Scan complete.${CLR}"
DTSMP=$(date +%F-%H%M)
#LINE 157 can be commented out after initiation creation of the 'nrw folder' for subsequent execution
sudo mkdir /var/log/nrw
sudo mkdir /var/log/nrw/"$VIP-$DTSMP"
sudo mv ~/"$VIP"* /var/log/nrw/"$VIP-$DTSMP"
echo "The saved who-is and nmap logs has been saved and can be found here: "
WHO=$(find /var/log/nrw/"$VIP-$DTSMP" -name "$VIP"-whois)
NMP=$(find /var/log/nrw/"$VIP-$DTSMP" -name "$VIP"-nmap)
echo -e "${BCYN}$WHO${CLR}"
echo -e "${BCYN}$NMP${CLR}"
echo ' '
echo 'Exiting Script.'
echo 'End of Session. Have a nice day'

#End of Script

#!/bin/bash
read -p "Enter User Name: "  username
read -p "Enter Password: "  password
file="$1"
lines=`cat $file`
for line in $lines; do
        echo "Updating the security patches for the host $line"
	HOSTS="$line"	
	SCRIPT="pwd;  echo -e 'PASSWORD' | sudo -S apt-get update && sudo apt-get upgrade -y && sudo reboot"
	SCR=${SCRIPT/PASSWORD/${password}}
     	sshpass -p ${password} ssh -l ${username} ${HOSTS[i]} "${SCR}"
done


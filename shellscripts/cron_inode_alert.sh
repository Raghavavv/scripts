#!/bin/bash
#Author: Raghava V
#inode Usage Alert

inode_alert()
{
	echo -e "\nHostname: `hostname`\nServer IP: `hostname -i`\n" > /root/inodeusagedata.txt	

	echo -e "\nInode usage of the server is at: $tot / \n" >> /root/inodeusagedata.txt

	echo -e "\nTop inode consuming Directories under / :\n----------------------------------------\n" >> /root/inodeusagedata.txt
	find / -xdev -printf '%h\n' | egrep -v 'virtfs|lib|kernels|bin|usr|openssl' | sort | uniq -c | sort -k 1 -n | tail -10 | sort -rn >> /root/inodeusagedata.txt
	mail -s "Inode_Usage_Warning-`hostname`-`hostname -i`" test@test.com < /root/inodeusagedata.txt
	rm -f /root/inodeusagedata.txt
}

tot=`df -i | egrep 'vda1|sda1' | awk '{print $5}' | cut -d'%' -f1`
if [[ $tot -le "95"  ]];then
	inode_alert;
else
	exit;
fi

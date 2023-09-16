#!/bin/bash

create_user(){
  #. $1 => username
  #. $2 => ssh public key
  echo "creating { $1 } system user..."
  useradd -m $1 && mkdir /home/$1/.ssh
  usermod -s /bin/bash -aG sudo $1
  echo "$1:1234567890" | chpasswd
  echo "$2" > /home/$1/.ssh/authorized_keys
}

create_ssh_2fa(){
  echo "enabling the ssh password authentication..."
  sed -i 's/PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config
  sed -i 's/ChallengeResponseAuthentication\ no/ChallengeResponseAuthentication\ yes\nAuthenticationMethods publickey,password/g' /etc/ssh/sshd_config
  systemctl reload sshd
}

create_motd(){
  echo "creating { message of the day } ..."
  cat << "EOF" > /etc/motd
 
                               )        (       )     )
     (      *   )  *   )    ( /(   *   ))\ ) ( /(  ( /(
     )\   ` )  /(` )  /((   )\())` )  /(()/( )\()) )\())
  ((((_)(  ( )(_))( )(_))\ ((_)\  ( )(_))(_)|(_)\ ((_)\
   )\ _ )\(_(_())(_(_()|(_) _((_)(_(_()|_))   ((_) _((_)
   (_)_\(_)_   _||_   _| __| \| ||_   _|_ _| / _ \| \| |
    / _ \   | |    | | | _|| .` |  | |  | | | (_) | .` |
   /_/ \_\  |_|    |_| |___|_|\_|  |_| |___| \___/|_|\_|
  
  #######################################################################
  This system is for the use of authorized users only. This system is a 
  property of Mobisy Technologies. Individuals using this computer system 
  are subject to having all their activities on this system monitored and 
  recorded by system personnel. Any misuse will be liable for prosecution 
  or other disciplinary actions.
  
   ** DISCONNECT IMMIDIATELY IF YOU ARE NOT AUTHORIZED PERSON !!!
  
  #######################################################################

EOF
}

CWAgent_install(){
	mkdir /tmp/tempcloudwatch
	cd /tmp/tempcloudwatch
	apt install wget -y
	wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
	sudo dpkg -i amazon-cloudwatch-agent.deb
	echo '{
		"metrics": {
			"append_dimensions": {
				"InstanceId": "${aws:InstanceId}"
			},
			"metrics_collected": {
				"disk": {
					"measurement": [
						"used_percent"
				],
					"metrics_collection_interval": 300,
					"resources": [
						"*"
					]
				},
				"mem": {
					"measurement": [
						"mem_used_percent"
					],
					"metrics_collection_interval": 300
				}
			}
		}
	}' >> /tmp/tempcloudwatch/awscwa_config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/tempcloudwatch/awscwa_config.json -s
}

install_site24x7agent(){
  sudo su
  wget https://staticdownloads.site24x7.in/server/Site24x7InstallScript.sh
  bash Site24x7InstallScript.sh -i -key=in_f7d14990e83486a80d50ef8fefef81fc -automation=true
}

create_user nikhil "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyiM7EagNkeh0FCMLMVsj5GDk4yydcpi5tNg3pNqyc5dEvuNhzl/wPdFLStByXE1l0cm3axB6gnpvk3Bp+DcRzER3X6Ym+Gf9Gt6h0vWKdLBhVYS3tpK29G0VK8kn/BQ1hkXZ6cLGwbWFc8pIVTwqsC/u2j4ojlDGNwfhiyd2XJdDi+eR2qbgbxPA/rQ7ls0EZq6tAPhwlQGC6a3xVG8xMT04gVbue5Jub/WryBBT7YnYAOscGPdyxkygFDtQa2eeCNRPI9d0ZmVrpOc3L3f+O3JSo1Q0fGnDd1gwOYQlla0oqqQwTP9dJjHyAgwI8vPJlywgmsRP8+X4e4xFWrlUgw== nikhil@nikhil-laptop"

create_user bhupendra "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDhrY3Ma206sEDoU+FvwcusZVfXvhk8TjZeiUZ4H5xyK5dVaiftrrnt+VJfw+FpS2N5JUmkP32bMZc6yKWHlJmOj1VaUco2aP9Cv/qxGfhIbofM/H4Cs69+gmWQGsN5vi0jIZtKPMGlophpUb6foesZkus8fONzzW/YKNrQpX/Ij6JhIK5sZPjdTMLnr3Qpsj0MPLL6ePJk2M4jsUtXGZ4KfBE6hZtUEH8m9+znDkhqSqvyGkiVbD5GP6dIIBbMn3gGHNT7juislBUoBiosvXyioGPxO1n/1x4LQOynfpIv5G7act18mNRXvRl+kIlFYX2FHRmU+wK/KbwnT2DwPeM7SiJh7YvOKka0rfvwpe28qGdZwD3fJbiZkNph/pQGwHtFavw5qO+QYn9RsZKcQ0Mi1xqF8tHBVd/pjB1IfeguF75a9KvvywKyyFuuvGyo/IhntUESVmstZs3831g4izJe9hcG3PZaht03wuxxJ6S7neFiUOErPVXdfrNHNG6Kh+8= bhupendra@MTPL-LT-DE-222"

create_motd
create_ssh_2fa
#CWAgent_install
install_site24x7agent
# Ansible playbooks

---

This folder consists of Ansilbe cookbooks for different client
installtions on EC2 servers. These are not fully autonomous playbooks,
as we need to manually change the firewall rules, assign roles to EC2
servers etc. Please follow this document to find out the step-by-step
process.

---

## Ansible Installation

Ansible is a configuration management tool which uses the SSH to
configure the instances. We first need to setup the control node for the
Ansible, for example: local workstation or ec2 server. 

### Adding the Ansible repository & Installation
```
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

### Setting up Ansible Inventory
Ansible inventory is the place where we declare the hosts & ip-addresses
on which we will deploy the clients using the playbooks. It can be found
at `/etc/ansible/hosts`. For example:
```
[frontend-servers]
fs1 1.2.3.4
fs2 2.3.4.5
[backend-servers]
bs1 2.1.2.1
bs2 3.1.2.3
```
Once we have populated the invetory, we can specify on which server or
group of servers the playbooks will run. To list all the inventory, run:
```
ansible-inventory --list
```

### Testing the Ansible Installtion
To test if the servers listed in the inventory file are reachable from
the control node, run:
```
ansible all -m ping -u root
```
To run the commands on multiple hosts, run:
```
ansible fs1:bs1:bs3 -a "uptime" -u root
```

## Cloudwatch Agent Installation
In order to monitor the Memory & disk usage on EC2 servers, we need to
add cloudwatch agent on each server. After the installtion, the agent
pushes the metrics to AWS cloudwatch. The cloudwatch agent configuration
file can be found at `templates/amazon-cloudwatch-agent.json`. If you
want to enable more metrics then edit this file.

### IAM Role Creation
For EC2 servers access the cloudwatch this to happen proper IAM role
is needed for EC2 server. The IAM role looks like this in our case 
(CloudWatchAgentServerRole):
```

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
```

### Assign the IAM Role to EC2 server
Go to EC2 console and right click on the EC2 server. Then select
`Attach/Replace IAM Role`. Select the newly created IAM role and click
`save`. Now we are ready to run the `logs` playbook on the server.

### Applying the Ansible playbook
By default Ansible will run playbook on all available hosts in inventory
. To apply the playbook, run:
```
ansible-playbook --private-key=/root/.ssh/StagMumSecret.pem -u ubuntu
cloudwatch.yml -v
```
If you have added the public key on the server and do not need the
private key, then run:
```
ansible-playbook -u gaurav cloudwatch.yml -K -v
```
`-K` is used when you need to run the sudo command with a password. `-v`
is used for verbose mode. If you want to debug the network connections
then use upto `-vvvv` in debug mode.
If you want to run playbook for specific host then use `-l`:
```
ansible-playbook -l bs1 -u gaurav cloudwatch.yml -K -v
```

## Filebeat Agent Installation
Filebeat agent installtion configuration file can be found at
`templates/filebeat.yml'.

### Update "templates/filebeat.yml"
Before executing the logs playbook please ensure the connectivity to the
elasticsearch by allowing the public ip address of the EC2 node in the
firewall/security-group. `filebeat.inputs:` section of the configuration
file dictates which files are going to be crawled by filebeat. These are
different for different servers and applications. For example, for 
frontend servers:
```
filebeat.inputs:
- type: log
  enabled: true
  paths: [ '/var/log/php7.3-fpm.log', '/var/log/nginx/*.log', '/var/log/bizomweblog/*.log' ]
```
Also verify if the Elasticsearch endpoint is correct, under the section
of `output.elasticsearch:`. For example,
```
output.elasticsearch:
  hosts: ["https://search-teselastic-ezg.ap-south-1.es.amazonaws.com:443]
```
The current version of the playbook supports the `oss-7.x` packeges
only. If you want some other version to be installed then edit the
`logs.yml` file.
To run the logs playbook:
```
ansible-playbook --private-key=/root/.ssh/StagMumSecret.pem -u ubuntu logs.yml -v
```

## OSSEC Agent Installation
There are two parts of the OSSEC agent installation, since we can only
register the OSSEC agent when the `ossec-authd` service is running on
the OSSEC server.

### On OSSEC server
Before executing the ossec playbook, we need to start the `ossec-authd`
server. This is necessary because we can only register the ossec agent
on the ossec-server using this service only. Otherwise we have to
manually generate/copy/paste the registration-key from the server to the
client.
CAUTION: Please ensure to run the `ossec-authd` service only when we
need to register clients because it does not need authentication. So any
client can register itself to the ossec-server. Hence, shut-down the
service immediately after the client registration.
```
/var/ossec/bin/ossec-authd -fnp 1515
```
This command will run the `ossec-authd` in foreground, no shared
password authentication & will listen on 1515 tcp port.
Cross-check the ip address of the ossec-server in the `ossec.yml`
playbook & in `templates/ossec.conf` before executing.
```
ansible-playbook -u gaurav ossec.yml -K -v
```
For more detailed information on manual installtion & registration, 
visit
[here](https://bitbucket.org/bizom/scripts/raw/9ad05f06be230b4cb0bb9b5d49a98225115b64b7/docs/ossec).

## Setting up [M]essage [O]f [T]he [D]ay
`motd.yml` playbook creates a file at `/etc/motd` to set the message of
the day.

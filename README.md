---

## Codebase for Infrastructure

---

This repository is managed by the DevOps team which contains various
kinds of scripts and other codebase to manage the infrastructure and
related services. This page contains just the overview of all folders
included in this repository. For detailed explanations read the
corresponding `README.md` file.

### Ansible
This folder contains the configuration files and related documentation
for the configuration management in our infrastructure. More details
about it can be found
[here](https://bitbucket.org/bizom/scripts/src/master/ansible/README.md).
### backup_mysql
It contains all the scripts which are responsible for managing the mysql
servers. This includes creating new mysql replica, creating automated
backups, compressing the mysql tables, consistency checker, taking the
dump of the individual database etc. More information
[here](https://bitbucket.org/bizom/scripts/src/master/backup_mysql/README.md).
### deployment
This folder contains the configuration files and scripts responsible for
the deployment pipeline for bitbucket and AWS ECS Fargate. The detailed
documentation can be found
[here](https://bitbucket.org/bizom/scripts/src/master/deployment/README.md).
### docs
It contains the older documentation before we started writing the
README files. We are moving the documentation
[here](https://bitbucket.org/bizom/scripts/src/master/docs/README.md).
### misc
It contains the scripts which does not fall under any other categories,
like script which creates the sftp user, script which tells if the
corresponding database for a codebase exists or not.
[Here](https://bitbucket.org/bizom/scripts/src/master/misc/README.md) is the
documentation.
### monitoring
To monitor the services inside our infrastructure we need to run some
custom scripts. We are keeping the grafana configuration here as well. 
The corresponding documentation can be found [here](https://bitbucket.org/bizom/scripts/src/master/monitoring/README.md).
### python
We have written some scripts in python to deal with the AWS APIs. For
example the script which sends hourly 5xx error count, script which
deletes the Route53 entries etc. Documentation is
[here](https://bitbucket.org/bizom/scripts/src/master/python/README.md).
### terraform
To create and manage the AWS ECS Fargate services we are using Terraform
tool. This folder contains all the configuration file to it. The
documentation can be found
[here](https://bitbucket.org/bizom/scripts/src/master/terraform/README.md).

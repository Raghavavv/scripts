# Using SSH keys for config-server

## Generating the SSH key-pair:

Run `ssh-keygen` command which will generate the ssh public and private
keypair. Generate the key-pairs for each environments `devel`, `staging`
and `prod`.

## Storing the Public key:

We are running one `config-server` for each environment. Each
`config-server` accesses the configuration repository whenever any
service asks for it. For example, we set `SPRING_PROFILES_ACTIVE`
variable to `devel` in case of `devel` environment, for service `ell`.
So the desired configuration will be accessing `ell-devel.yml` file from
the `bizom-configurations` git repository. Similarly for `prod`
environment the config-server will be accessing `bizom-prod-config`.

Hence, we are going to put the public key in the configuration
repository. To do this,
* Go to `Settings`.
* Go to `Access keys`.
* Click on `Add key`, put the `label` name as per environment name and
  paste the respective public key (content of `~/ssh/id_rsa.pub`.
  
## Storing the Private key:

Once we put the SSH public key in place, its time to put the private key
somewhere, from which it can be downloaded while building the container.
To perform this operation we will create one folder for each environment
inside the S3 bucket:
* `deploy.mobisy.com/devel/config`   - for `devel` environment.
* `deploy.mobisy.com/staging/config` - for `staging`.
* `deploy.mobisy.com/prod/config`    - for `prod`.
Upload the SSH private key `~/.ssh/id_rsa` to the environment's
respective S3 bucket folder. `deploy.mobisy.com/devel/config/id_rsa` for
`devel` environment.

## Updating the "./src/main/resources/application.properties":

Till now, we were using `username` and `password` to access the
configuration repository. But now we will use SSH keys to access the
repository. Remove `username` and `password`. Add this to the file 
(for `devel` and `staging`):
```
spring.cloud.config.server.git.uri=git@bitbucket.org:bizom/bizom-configurations.git
```
For `prod` environment:
```
spring.cloud.config.server.git.uri=git@bitbucket.org:bizom/bizom-prod-config.git
```
## Fetching the Private key inside the bitbucket-pipeine:

Change the `build()` function in `bizom-config-server/ops/deploy.sh`:

```
build(){
  #. $1 => deploy service/container image name
  #. $2 => environment name
  echo "###############################################################"
  echo "downloading ssh-key for git repository permissions from S3"
  aws s3 cp s3://deploy.mobisy.com/$2/$1/id_rsa ops/$2/
  echo "building the { $1 } docker container images"
  cp ops/$2/Dockerfile . && docker build -t $1 . --rm
  echo "###############################################################"
}
```
Change the `bizom-config-server/ops/$ENVIRONMENT/Dockerfile` to add the
support for private key.

```
FROM maven:3.5.2
WORKDIR /root/bizom-config-server
ADD ./ /root/bizom-config-server/
RUN mkdir /root/.ssh
COPY ops/devel/id_rsa /root/.ssh
RUN chmod 400 /root/.ssh/id_rsa
EXPOSE 8102
CMD ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts && mvn spring-boot:run
```

Whenever the container runs, it will try to SSH into the repository
which will ask to confirm the SSH fingerprint. Since we are running in
non-interactive mode, we must automate this process. To do this we have
added the following line in the `Dockerfile`, which will automatically
add the bitbucket servers in `known_hosts` file:
```
CMD ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts && mvn spring-boot:run
```
In case of `prod` environment, we add the following line to change the
git repository URL:
```
RUN sed -i 's/bizom-configurations/bizom-prod-config/g' /root/bizom-config-server/src/main/resources/application.properties
```

## Updating the task definition:

The final step is to add the SSH fingerprint automation command to the
respective ECS `task-definition` for each environment. To perform this
operation modify the `Command` section of the `task-definition` as
follows:
```
sh,-c,ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts; mvn spring-boot:run
```


# Systemd unit files

## PHP Consumer: 
To run the php consumer process using systemd unit file
create one file named "/etc/systemd/system/consumer@.service". Here, "@"
in the name of the service tells us that it takes argument from user to
start multiple processes from the same unit file. The content of the
file is as follows:

```
[Unit]
Description=Running php consumers for %I
Requires=network.target
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=ubuntu
ExecStart=/usr/bin/env php /usr/share/php/PhpConsumerProducer/Consumereditlog.php 10.127.12.229:9092 %i 
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```
* To start the consumer process with multiple arguments run:
```
sudo systemctl start consumer@editlog.service
sudo systemctl start consumer@schemes.service
sudo systemctl start consumer@users.service
sudo systemctl start consumer@outlets.service
sudo systemctl start consumer@skunits.service
sudo systemctl start consumer@warehouses.service
```
* To check the status of the processes:
```
sudo systemctl status consumer@editlog.service
sudo systemctl status consumer@schemes.service
sudo systemctl status consumer@users.service
sudo systemctl status consumer@outlets.service
sudo systemctl status consumer@skunits.service
sudo systemctl status consumer@warehouses.service
```
* To enable the processes on system startup:
```
sudo systemctl enable consumer@editlog.service
sudo systemctl enable consumer@schemes.service
sudo systemctl enable consumer@users.service
sudo systemctl enable consumer@outlets.service
sudo systemctl enable consumer@skunits.service
sudo systemctl enable consumer@warehouses.service
```


## MDM Worker:
To run the mdm worker process we need to do the following changes:
* Add the `-app /var/sites/newstaging.bizom.in/app/` in `cake` command
to run it from anywhere in the filesystem. Without using this option, we
need to first change the directory and then run the command.
* Since mdm-worker process runs the worker in the background, the
systemd unit process gets exited. To stop this behaviour of the mdm
process we need to remove the `&` from the following two plugin files:
* /usr/share/php/cakeresque/Plugin/CakeResque/Console/Command/CakeResqueShell.php
* /usr/share/php/signupresque/Plugin/CakeResque/Console/Command/CakeResqueShell.php
search for the following block in these two files and remove the last `&`
which sends the whole process into background.
    ```
    "2>&1\" >/dev/null 2>&1 &"
    ```
* Once we make these changes let's create the systemd unit file named
`mdm-worker.service` inside the systemd configuration directory
`/etc/systemd/system/`.
```
[Unit]
Description=Running the mdm worker
Requires=network.target
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=5
User=ubuntu
ExecStart=sudo /usr/share/php/Cake_2.10/Cake/Console/cake -app /var/sites/newstaging.bizom.in/app/ CakeResque.CakeResque start -v
#StandardOutput=append:/home/ubuntu/mdm-worker.log
#StandardError=append:/home/ubuntu/mdm-worker.log

[Install]
WantedBy=multi-user.target
```
* To start the mdm-worker process run:
```
sudo systemctl start mdm-worker.service
sudo systemctl stop mdm-worker.service
```
To enable it on system startup ru:
```
sudo systemctl enable mdm-worker.service
```

#!/bin/bash

#. Find out the number of threads in the CPU. Suppose the system has 16
# cores, dump and restore process will utilize all of these cores.
no_of_threads="$(/bin/cat /proc/cpuinfo | /bin/grep processor | /usr/bin/wc -l)"

#. Populate these variables before running the script. These are the
# credentials and endpoint of the remote database from where we will 
# take the dump.
remote_db=""
remote_db_port="3306"
remote_db_user=""
remote_db_pass=""

local_db="localhost"
local_db_port="3306"
local_db_user=""
local_db_pass=""

log_level="3"
log_file="/mnt/mydumper.log"
output_dir="/mnt/dump"
binlog_dir="/home/logs/mysql"

#. Creating the directory to store the binlogs and giving the full
# permission to the "mysql" user.
mkdir -p $binlog_dir
touch $binlog_dir/mysql-bin.index

#. Populating the mysql credentials configuration file with the remote
# mysql database so that we need not supply the credentials on the
# command line.
echo "[client]" > ~/remote_server.conf
echo "user=$remote_db_user" >> ~/remote_server.conf
echo "password=$remote_db_pass" >> ~/remote_server.conf
echo "host=$remote_db" >> ~/remote_server.conf

echo "[client]" > ~/local_server.conf
echo "user=$local_db_user" >> ~/local_server.conf
echo "password=$local_db_pass" >> ~/local_server.conf
echo "host=$local_db" >> ~/local_server.conf

create_fs(){

  #. This function identifies the new disk (SSD). Formats with EXT4 file
  # system, and mounts it to /mnt. It installs the mydumper program
  # which dumps the database.

  echo "updating the system and installing mydumper/myloader"
  sudo /usr/bin/apt -y update
  wget https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper_0.9.5-2.xenial_amd64.deb
  dpkg -i mydumper_0.9.5-2.xenial_amd64.deb
  SSD="$(sudo /sbin/fdisk -l | /bin/grep /dev/nvm | /usr/bin/cut -d' ' -f2 | /usr/bin/cut -d':' -f1)"
  echo "formatting the SSD with EXT4 file-system"
  sudo /sbin/mkfs.ext4 $SSD
  echo "mounting the SSD to /mnt and creating the mysql directory"
  sudo /bin/mount -t ext4 $SSD /mnt
  sudo /bin/mkdir /mnt/mysql

  #. Adding new entry in /etc/fstab, so that on startup the new disk gets
  #  mounted automatically.
  UUID="$(sudo /sbin/blkid | /bin/grep nvm | /usr/bin/cut -d' ' -f2)"
  echo "adding the entry in /etc/fstab"
  /bin/echo "$UUID /mnt auto defaults,nofail 0 0" | /usr/bin/tee -a /etc/fstab

}

create_config(){

  echo "configuring the apparmor for the new mysql-server configuration"
  grep -q -F 'alias /var/lib/mysql/ -> /mnt/data/mysql/,' /etc/apparmor.d/tunables/alias || echo "alias /var/lib/mysql/ -> /mnt/data/mysql/," >> /etc/apparmor.d/tunables/alias
  grep -q -F 'alias /var/log/mysql/ -> /home/logs/mysql/,' /etc/apparmor.d/tunables/alias || echo "alias /var/log/mysql/ -> /home/logs/mysql/," >> /etc/apparmor.d/tunables/alias
  echo "backing up the existing my.cnf configuration file"
  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.bak

  #. Creating the mysql configuration file.
  server_id=$(cat /dev/urandom | tr -dc '0-9' | fold -w 7 | head -n 1)
  cat <<EOF > /etc/mysql/my.cnf
	[mysqld]
	!includedir /etc/mysql/conf.d/
	!includedir /etc/mysql/mysql.conf.d/
	datadir=/mnt/data/mysql
	binlog_format=ROW
	character_set_server=utf8mb4 
	collation_server=utf8mb4_unicode_ci
	explicit_defaults_for_timestamp=1
	innodb_file_per_table=ON
	innodb_flush_log_at_trx_commit=2
	innodb_flush_neighbors=0
	innodb_io_capacity=800
	join_buffer_size=4194304
	log_bin_trust_function_creators=1
	log_slave_updates=1
	lower_case_table_names=1
	max_allowed_packet=134217728
	max_heap_table_size=134217728
	read_buffer_size=262144
	read_rnd_buffer_size=524288
	sync_binlog=0
	table_definition_cache=5000
	table_open_cache=10000
	table_open_cache_instances=16
	tmp_table_size=134217728
	replicate-ignore-db=mysql
	expire_logs_days=2
	server-id=$server_id
	sql_mode=''
	replicate_wild_ignore_table = 'mysql.%'
	innodb_buffer_pool_size = 30G
	innodb_log_buffer_size = 256M
	innodb_log_file_size = 2G
	innodb_write_io_threads = 8
	innodb_flush_method = O_DIRECT
	log_bin=$binlog_dir/mysql-bin.log
	max_binlog_size=100M
	log_slave_updates=true
	secure-file-priv=""
EOF

}

prepare() {

  if [[ $(dpkg -l | grep mysql-server-5.7) ]]; then
    echo "the { mysql-server-5.7 } is already installed"
  else
    echo "installing the { mysql-server-5.7 }"
    apt -y install mysql-server-5.7 mysql-client-core-5.7
  fi
  if [[ $(netstat -tunlp | grep 3306) ]]; then
    echo "stopping the mysql-server"
    systemctl stop mysql.service
  fi
  chown -R mysql:mysql /home/logs
  echo "syncing the existing mysql data-directory to new location"
  rsync -av /var/lib/mysql /mnt/data
  echo "backing up the existing configuration"
  mv /var/lib/mysql /var/lib/mysql.bak
  cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak
  echo "creating the mysql custome configuration"
  create_config
  sed -i 's/\/var\/lib\/mysql/\/mnt\/data\/mysql/g' /etc/mysql/mysql.conf.d/mysqld.cnf
  echo "restarting the apparmor and mysql-server"
  systemctl restart apparmor.service mysql.service

}

dump() {

  /bin/echo "show databases" | /usr/bin/mysql --defaults-extra-file=~/remote_server.conf | /bin/grep -Ev "(^Database|common_schema|sys|mysql|performance_schema|information_schema)$" > databases
  candidates_list1="parleagro_bizom_in_bizom"
  candidates_list2=$(cat databases | awk '/^2|^a|^b|^c|^d|^e|^f/')
  candidates_list3=$(cat databases | awk '/^g|^h|^i|^j|^k|^l|^m/')
  candidates_list4=$(cat databases | grep -Ev "(^parleagro_bizom_in_bizom)" | awk '/^n|^o|^p|^q|^r|^s|^t/')
  candidates_list5=$(cat databases | awk '/^u|^v|^w|^x|^y|^z/')
  dumper "${candidates_list1[*]}" "candidates_list1"
  dumper "${candidates_list2[*]}" "candidates_list2" &
  dumper "${candidates_list3[*]}" "candidates_list3" &
  custom_wait
  dumper "${candidates_list4[*]}" "candidates_list4" &
  dumper "${candidates_list5[*]}" "candidates_list5"
  custom_wait

}

custom_wait() {

  while [[ $(uptime | awk '{print $11}' | cut -d',' -f1) > 2.0 ]]; do
    echo "the 5 minutes load average is more than TWO. Sleeping for 10 seconds..."
    sleep 10
  done
  echo "the 5 minutes load average is less than TWO, hence launching another instance of the process"

}

dumper() {

  #$1 => list of the databases.
  #$2 => directory name to store the dumped files.
  echo "creating the directory for the dump /mnt/dump"
  mkdir -p $output_dir/$2
  for candidate in $1; do
    echo "dumping... the database { $candidate }"
    mydumper -c -C -t $no_of_threads -u $remote_db_user -h $remote_db --password $remote_db_pass -B $candidate --outputdir $output_dir/$2 --logfile $log_file -v $log_level --triggers --routines --no-locks --success-on-1146 --long-query-guard 100000
  done

}

restore() {

  echo "dump directory creation on root volume"
  mkdir ~/dump
  candidates_list="candidates_list1 candidates_list2 candidates_list3 candidates_list4  candidates_list5"
  for list in ${candidates_list[*]}; do
    myloader -o -u $local_db_user --password $local_db_pass -h localhost -t $no_of_threads -v $log_level -d $output_dir/$list | tee -a /mnt/$list.log
    echo "moving { $output_dir/$list } directory to the root volume."
    mv $output_dir/$list ~/dump
  done
  echo "dumping and restoring the time_zone tables"
  time_tables=$(/usr/bin/mysql --defaults-extra-file=~/remote_server.conf -e 'use mysql; show tables;'| grep time_zone)
  for time_table in ${time_tables[*]}; do
    mkdir -p $output_dir/$time_table
    mydumper -c -C -t $no_of_threads -u $remote_db_user -h $remote_db --password $remote_db_pass -B mysql -T $time_table --outputdir $output_dir/$time_table --logfile $log_file -v $log_level --triggers --routines --no-locks --success-on-1146  --long-query-guard 100000
    myloader -u $local_db_user --password $local_db_pass -h localhost -t $no_of_threads -v $log_level -d $output_dir/$time_table | tee -a /mnt/$time_table.log
  done

}

post_install() {

  mysql -u $local_db_user -p$local_db_pass -h localhost -e "create user 'redshift'@'localhost' identified by 'Mobisy_321';"
  mysql -u $local_db_user -p$local_db_pass -h localhost -e "grant file, select, super, lock tables,REPLICATION SLAVE, REPLICATION CLIENT  on *.* to 'redshift'@'localhost'"
  apt -y install openjdk-8-jdk maven postgresql-client-common postgresql-client-10
  chmod 755 /mnt /mnt/data /mnt/data/mysql
  mkdir /mnt/data/mysql/csv
  chmod 777 /mnt/data/mysql/csv
  chown redshift:redshift /mnt/data/mysql/csv
  git clone https://bitbucket.org/bizom/redshiftplatform.git
  cd ./redshiftplatform/ && git checkout development
  cd ./EC2_Redshift_Migration && mvn install && mvn clean package

}

echo "creating the file system"
create_fs
echo "preparing the local mysql-server-5.7 for dump/restore"
prepare
if [[ $(netstat -tunlp | grep 3306) ]]; then
  echo "stopping the replication process"
  mysql -u $remote_db_user -p$remote_db_pass -h $remote_db -e 'call mysql.rds_stop_replication;'
  echo "starting the dump/restore process"
  dump
  restore
  post_install
else
  echo "mysql-server is not running"
  exit
fi

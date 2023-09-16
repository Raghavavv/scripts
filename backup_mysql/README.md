# MySQL Management

---

`backup_mysql` is the folder which contains all the script responsible
for managing the mysql database in our infrastructure. For example,
creating new EC2 replica, creating the backup, compressing the database,
creating the daily & monthly backup etc. Currently there are 6 bash
scripts.

---

## EC2 MySQL slave creation process

In order to populate the AWS redshift we run a mysql slave with custom
code written in java. AWS redshift is a modified version of Postgres
database. The flow of data is as follows:
```
AWS RDS Master (MySQL) => EC2 MySQL slave => AWS Redshift (Postgres)
```
The creation of EC2 MySQL slave consists of the following steps:

* Create a read-replica of the RDS Master and wait for it to get synced
completely with the master.

* Once the newly created read-replica catches up with the master stop
the replication with the folowing mysql command:
```
CALL mysql.rds_stop_replication;
```

* After stopping the read-replica replication we need to note down the
binlog position. Run this command:
```
show slave status\G
```
A sample output of the above command is:
```
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: bizommaster.asdf123.region.rds.amazonaws.com
                  Master_User: rds_replica_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin-changelog.639865
          Read_Master_Log_Pos: 9126872
               Relay_Log_File: relaylog.003313
                Relay_Log_Pos: 6414824
        Relay_Master_Log_File: mysql-bin-changelog.639865
             Slave_IO_Running: No
            Slave_SQL_Running: No
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: mysql.plugin,mysql.rds_monitor,mysql.rds_sysinfo,innodb_memcache.cache_policies,mysql.rds_history,innodb_memcache.config_options,mysql.rds_configuration,mysql.rds_replication_status
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 6415235
              Relay_Log_Space: 9127424
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 226239612
                  Master_UUID: 667a1951-9b28-11e7-8bf1-22000aaca7b0
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: 
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version:
```

Note down the following fields. These will be used to sync the EC2
replica with the RDS master.
```
              Master_Log_File: mysql-bin-changelog.639865
          Read_Master_Log_Pos: 9126872
```

* Take the dump from the RDS read-replica using `mydumper` tool.

* Restore the taken dump into local EC2 mysql, using `myloader`.
Although we can install the `mydumper/myloader` using the standard apt
package manager but there is some issue with the version of the tool.
Hence we are downloading it manually and then installing using `dpkg`.
Both of these tools can be installed using the following command:
```
wget https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper_0.9.5-2.xenial_amd64.deb
dpkg -i mydumper_0.9.5-2.xenial_amd64.deb
```

* Once the restore process gets completed, we need to chceck the
consistency of the local EC2 mysql database. To perform this process we
have already written `check_db_consistency.sh` script. It counts the
number of rows in each table of all the databases and then compares it
to the rows in the remote read-replica.

* As the SSD attached is only 1.7 TB capacity and the mysql database is
over 2 TB, we need to compress all the tables. We can use the script
`compression.sh` to automatically compress all the tables. It can be
found in this folder. More about this script scroll this page.

* If the consistency script does not report any inconsistencies in the
databases, then we can start the mysql slave. To start the slave run the
following mysql command:
```
CHANGE MASTER TO
MASTER_HOST='bizommaster.asdf123.region.rds.amazonaws.com',
MASTER_USER='sys_replica_user',
MASTER_PASSWORD='password',
MASTER_PORT=3306,
MASTER_LOG_FILE='mysql-bin-changelog.613788',
MASTER_LOG_POS=123270974;
```

* To start the slave run:
```
start slave;
```

* * *
* * *

### ** [backup.sh](https://bitbucket.org/bizom/scripts/src/master/backup_mysql/backup.sh) script **

This script is responsible for creating the EC2 mysql replica explained
above. It consists of many bash functions to provide all the
functionality needed. Here is the explanation for the each function:

* **create_fs() function:** This function installs the `mydumper/myloader`
, creates the ext4 file-system on local SSD and then creates an entry in
the `/etc/fstab` entry so that the SSD automatically mounts on system
startup. 
NOTE: We use EC2 which comes with SSD. Be careful while restarting the
server. If we restart the server without entry in `/etc/fstab`, the SSD
will go away and there is no way to recover the data on the disk. Hence,
after creating the fstab entry, try restarting the server before taking
dump of the database. This will ensure that on any system reboot the
external SSD will persist the data.
```
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
  /bin/echo "UUID=$UUID /mnt auto defaults,nofail 0 0" | /usr/bin/tee -a /etc/fstab

}
```

* **prepare() function:** It checks if the mysql-server and corresponding
dependencies have been installed on the server or not. If it is already
running then do nothing otherwise installed `mysql-server-5.7`. Then it
rsync s the content of the `/var/lib/mysql` into `/mnt/data` directory.
This folder by default resides on the standard EBS volume of the EC2
server. We explicitly copy the contents of mysql default directory into
the SSD storage. It also calls the create_config() function and restarts
the `mysql` and `apparmor` services.
```
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
```

* **create_config() function:** This function creates the configuration for
the mysql server as well as the apparmor service. As mentioned in the
previous function explanation that we are moving the default mysql data
directory from `/var/lib/mysql` to `/mnt/data`. Hence we need to allow
it in apparmor configuration otherwise the mysql service will not start
due to apparmor blocks it. The configuration file for apparmor is
located at `/etc/apparmor.d/tunables/alias`. This function also creates
a 7 digits server-id randomly which is used to register the local mysql
server as a slave in RDS master. Then it populates the
`/etc/mysql/my.cnf` mysql configuration file with the custom parameters.
These parameters are optimized for 60 GB RAM.
```
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
```

* After configuration functions, the following code block is executed.
It checks if the mysql-server is running and listening on the port 3306
it stops the replication of the remote RDS read-replica. Then it calls
the `dump()` and `restore()` functions serially. After that
`post_install()` function is called. If the mysql-server is not running
the script exits.
```
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
```

* **dump() function:** This function dumps the database from the RDS
read-replica. In order to understand what this function does please
consider the following points:
    1. We have over 400 databases, each containing over 330 tables.
    `mydumper` dumps the data as individual tables with one table per core 
    at a time.
    2. As we start dumping all the databases, it will create over 120000
    files under single directory. Operating on such large number of files 
    is very inconvenient. To deal with this we have logically divided the
    databases into total 5 categories. This division is on alphabetical
    basis.
    3. `candidates_list1` contains the parleagro database as it is the
    largest database in terms of storage size (over 275 GB).
    `candidates_list2` contains the list of the database which start from
    the alphabet `a` to `f`. Similarly other database lists are created.
    3. Suppose we are running it on a 8 core EC2 server. 8 threads will
    be launched by `mydumper`. The dump starts with the `candidates_list1`.
    We can start with the `candidates_list2` only after the first list gets
    completed. It takes too much time when the threads start exiting. Since
    all the parallel threads take the dump of different tables some threads
    take longer to exit (sometimes over 30 minutes). To overcome this issue
    and optimize the speed of dumping process we start with another list in
    the meantime the last threads fetch their assigned data.
    4. When to start with the next database list ? The answer is quite
    simple, when the system load goes less than 2. `custom_wait()` function
    handles this by waiting for the load to get reduced under 2. Because by
    now at least 5 threads would have exited. This way we can take the dump
    in a faster way. `dumper()` function is responsible for calling the
    `mydumper` command for the list by traversing on the array containing
    the list of databases.
    NOTE: We can always manually dump the individual list inside
`screen` session. This is the fastest method of dumping the whole
database. But the downside is that you need to monitor the progress
every hour or so to check whether the previous list is complete or not.

```
dump() {

  /bin/echo "show databases" | /usr/bin/mysql --defaults-extra-file=/root/server.conf | /bin/grep -Ev "(^Database|common_schema|sys|mysql|performance_schema|information_schema)$" > databases
  candidates_list1="parleagro_bizom_in_bizom"
  candidates_list2=$(cat databases | awk '/^2|^a|^b|^c|^d|^e|^f/')
  candidates_list3=$(cat databases | awk '/^g|^h|^i|^j|^k|^l|^m/')
  candidates_list4=$(cat databases | grep -Ev "(^parleagro_bizom_in_bizom)" | awk '/^n|^o|^p|^q|^r|^s|^t/')
  candidates_list5=$(cat databases | awk '/^u|^v|^w|^x|^y|^z/')
  dumper "${candidates_list1[\*]}" "candidates_list1" &
  custom_wait
  dumper "${candidates_list2[\*]}" "candidates_list2" &
  dumper "${candidates_list3[\*]}" "candidates_list3" &
  custom_wait
  dumper "${candidates_list4[\*]}" "candidates_list4" &
  dumper "${candidates_list5[\*]}" "candidates_list5" &
  custom_wait

}
```

* **dumper() function:** It creates the candidates_list directory inside
the the `/mnt/` directory. Then traverses on the array which contains
the list of the databases. `-C` options compresses the database which
gives us extra space on the disk.
```
dumper() {
  #$1 => list of the databases.
  #$2 => directory name to store the dumped files.
  echo "creating the directory for the dump /mnt/dump"
  mkdir -p $output_dir/$2
  for candidate in $1; do
    echo "dumping... the database { $candidate }"
    mydumper -c \
             -C \
             -t $no_of_threads \
             -u $remote_db_user \
             -h $remote_db \
             --password $remote_db_pass \
             -B $candidate \
             --outputdir $output_dir/$2 \
             --logfile $log_file \
             -v $log_level \
             --triggers \
             --routines \
             --no-locks \
             --success-on-1146 \
             --long-query-guard 100000
  done
}
```

* **restore() function:** After the dump process gets completed this
function restores all the tables into the local EC2 mysql database. It
also dumps the time_zone tables from the RDS read-replica and restore
into the local mysql database. Again this step can also be run manually
depending upon the requirements.
```
restore() {

  candidates_list="candidates_list1 candidates_list2 candidates_list3 candidates_list4  candidates_list5"
  for list in ${candidates_list[\*]}; do
    myloader -o \
             -u root \
             -h localhost \
             -t $no_of_threads \
             -v $log_level \
             -d $output_dir/$list | tee -a /mnt/$list.log
  done
  echo "dumping and restoring the time_zone tables"
  time_tables=$(/usr/bin/mysql --defaults-extra-file=/root/server.conf -e 'use mysql; show tables;'| grep time_zone)
  for time_table in ${time_tables[\*]}; do
    mkdir -p $output_dir/$time_table
    mydumper -c \
             -C \
             -t $no_of_threads \
             -u $remote_db_user \
             -h $remote_db \
             --password $remote_db_pass \
             -B mysql \
             -T $time_table \
             --outputdir $output_dir/$time_table \
             --logfile $log_file \
             -v $log_level \
             --triggers \
             --routines \
             --no-locks \
             --success-on-1146  \
             --long-query-guard 100000
    myloader -u root \
             -h localhost \
             -t $no_of_threads \
             -v $log_level \
             -d $output_dir/$time_table | tee -a /mnt/$time_table.log
  done

}
```

* **post_install() function:** After the restore process is complete, we
sync the newly created local EC2 mysql with the RDS master. The steps
involved are already documented in this page, see `EC2 MySQL slave
creation process` section of the README.md file. At the time of writing
this documentation `post_install()` function is called manually. It
prepares the database by creating new local mysql user for the redshift
syncing process. Then `postgres-client-10` installed with its
dependencies. Then we clone the code repository which contains the
codebase of the jave application which pushes data from the EC2 mysql
slave into redshift. It then compiles the java code and run the jar
files.
    NOTE: At the time of writing all these steps are carried out by the
dev team, not the DevOps team, except the mysql user creation.
```

post_install() {

  mysql -u root -h localhost -e "create user 'redshift'@'localhost' identified by 'password';"
  mysql -u root -h localhost -e "grant file, select, super, lock tables,REPLICATION SLAVE, REPLICATION CLIENT  on *.* to 'redshift'@'localhost'"
  apt -y install openjdk-8-jdk maven postgresql-client-common postgresql-client-10
  chmod 755 /mnt /mnt/data /mnt/data/mysql
  mkdir /mnt/data/mysql/csv
  chmod 777 /mnt/data/mysql/csv
  chown redshift:redshift /mnt/data/mysql/csv
  git clone https://bitbucket.org/bizom/redshiftplatform.git
  cd ./redshiftplatform/ && git checkout development
  cd ./EC2_Redshift_Migration && mvn install && mvn clean package

}
```

* * *
* * *
### ** [compression.sh](https://bitbucket.org/bizom/scripts/src/master/backup_mysql/compression.sh) script **

This script compresses all the tables in all the databases inside the
EC2 mysql slave server. It lists all the databases then loop on each
database to fetch the list of tables and then compresses each table
using the following command. The compression script also logs the size
of each table before and after compression. This is achieved by
comparing the size of the `*.ibd` file inside the mysql data directory.
```
mysql -u $remote_db_user \
      -h $remote_db \
      -p$remote_db_pass \
      -e "use $database;ALTER TABLE $table ROW_FORMAT=COMPRESSED;" >> comparison_errors.log 2>&1
```
To get the size of each table:
```
echo "Size of { $database/$table } before compression is: $(du -sh $mysql_data_dir/$database/$table.ibd | awk '{print $1}')" | tee -a comparison.log
echo "Size of { $database/$table } after compression is: $(du -sh $mysql_data_dir/$database/$table.ibd | awk '{print $1}')" | tee -a comparison.log
```
* * *
* * *

### ** [backup_monthly.sh](https://bitbucket.org/bizom/scripts/src/master/backup_mysql/backup_monthly.sh) script **

As we know there is an automated backup creation policy in AWS RDS which
allows us to restore the RDS point-in-time recovery upto 35 days. But we
keep the backup on every first day of the month for at least 6 months.
Backups older than 6 months created by this scripts are automatically
curated. The script itself is well documented. It contains 4 functions
in total. In order to identify the snapshots created by this script we
uniquely tag all the snapshots with creation timestamp along with a 15
characters random string. We are using random string to create unique 
"target-db--snapshot-identifier". We are tagging the random string 
"tihymrb" to each snapshot created by this script. This will make sure
that we are not curating snapshots of the RDS database, created by other
means/users. This script currently resides on Miscellaneous server.
```
unix_timestamp=$(date +%s)
random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
```
* **snapshot_copy() function:** It creates the copy of the latest
overnight snapshot created automatically by AWS RDS. "aws rds 
describe-db-snapshots" option returns a sorted list of the snapshots 
with oldest snapshot on the top. Hence we are sorting the list of 
available "automated" backups in the reverse order.
```
snapshot_copy(){
  latest_snapshot=$(aws rds describe-db-snapshots --snapshot-type automated | jq -r .DBSnapshots[].DBSnapshotIdentifier | grep $database_name | sort -r | sed '1q' | cut -d':' -f2)
  aws rds copy-db-snapshot --source-db-snapshot-identifier "rds:${latest_snapshot}" --target-db-snapshot-identifier "${latest_snapshot}-tihymrb-${unix_timestamp}-${random}"
  #. Wait until the newly created snapshot is available, once it is
  #  available call the snapshot_curation function.
  while [[ $(aws rds describe-db-snapshots --snapshot-type manual --db-snapshot-identifier ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} | jq -r .DBSnapshots[].Status) != "available" ]]; do
    echo "waiting for the snapshot to finish...sleeping for 2 minutes."
    sleep 120
  done
  if [[ $(aws rds describe-db-snapshots --snapshot-type manual --db-snapshot-identifier ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} | jq -r .DBSnapshots[].Status) == "available" ]]; then
    echo "snapshot was successful."
    snapshot_curation "successful"
  else
    echo "snapshot was unsuccessful"
    #snapshot_curation "unsuccessful"
    exit 1
  fi
}
```

* **snapshot_curation() function:** It performs the following operations
    * Get the list of "manual" database snapshots.
    * Check if the number of manual snapshots is greater than 6.
    * If the number is greater than 6 than fetch the list of "manual" 
    snapshots and delete the oldest one.
    * call the email function `send_email` to send the alert to the DevOps
    team.
```
snapshot_curation(){
  #. $1 => status of the snapshot.
  manual_snapshot_count=$(aws rds describe-db-snapshots --snapshot-type manual | jq -r .DBSnapshots[].DBSnapshotIdentifier | grep "^${database_name}-\S\*-tihymrb-\S\*" | wc -l)
  if [[ $manual_snapshot_count > 6 ]]; then
    echo "Snapshot count is exceeding the 6 months limit. deleting the oldest snapshot"
    db_snapshot_remove=$(aws rds describe-db-snapshots --snapshot-type manual | jq -r .DBSnapshots[].DBSnapshotIdentifier | grep "^${database_name}-\S\*-tihymrb-\S\*" | head -1)
    snapshot_delete $db_snapshot_remove
    echo "sending the email alert."
    message="monthly backup for $database_name is $1.\nThe newly created snapshot is named: { ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} }.\nMore than 6 months backup available.\nCurated snapshot { $db_snapshot_remove }."
    send_email "$message"
  else
    echo "Less than 6 months backup available. no curation needed."
    echo "sending the email alert."
    message="monthly backup for $database_name is $1.\nThe newly created snapshot is named: { ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} }.\nLess than 6 months backup available, hence no curation needed."
    send_email "$message"
  fi
}
```

* * *
* * *

### ** [client_db_dump.sh](https://bitbucket.org/bizom/scripts/src/master/backup_mysql/client_db_dump.sh) script **

This script is used to clone the database from production mysql server
into staging mysql server manually. Also, we are using this script to
send the daily and weekly database dumps to our client companies using
the appropriate crontab entries. This script currently resides on
Miscellaneous server. It contains the following functions. 
    * `dump()` function dumps the database using `mysqldump`. We do not
    use `mydumper` for this script because the file formats are 
    different in case of both tools. `mysqldump` creates one single file
    of the whole database whereas `mydumper` creates one file per table.
    Also, not everyone using `myloader` to import the database into 
    there mysql installation.
    * `compress()` function compresses the dumped database using tar
    with gzip compression.
    * `upload()` function uploads the compressed database file to AWS S3
    from where we get a sharable public url. And `cleanup()` function
    deletes the files involved in this whole process.
    * NOTE: We use tags, generated by 15 characters random string along
    with the current Unix timestamp to avoid collision between the
    uploaded backup files for the same database.
```
dump(){
  mysqldump -v \
            --log-error=$dump_dir/error.log \
            --max_allowed_packet=1024M \
            --force \
            --routines \
            --quick \
            --single-transaction=TRUE \
            -h $db_host \
            -u $db_user \
            -p$db_pass $1 > $dump_dir/${1}.sql
  echo "Dump size: $(du -sh $dump_dir/${1}.sql | awk '{print $1}')" >> $dump_dir/email.txt
}
compress(){
  cd $dump_dir && tar -zcvf ${1}\_${tag}.tar.gz ${1}.sql
  echo "Archive size: $(du -sh $dump_dir/${1}\_${tag}.tar.gz | awk '{print $1}')" >> $dump_dir/email.txt
}
upload(){
  aws s3 cp $dump_dir/${1}_${tag}.tar.gz s3://$s3_bucket/
  echo "Download link: $s3_bucket/${1}\_${tag}.tar.gz"$'\n' | tee -a $dump_dir/email.txt
}
cleanup(){
  rm -f $dump_dir/\*.sql $dump_dir/\*.tar.gz
}
```

* * *
* * *

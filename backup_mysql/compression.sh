#!/bin/bash

remote_db=""
remote_db_port=""
remote_db_user=""
remote_db_pass=""
mysql_data_dir="/mnt/data/mysql/"

echo "[client]" > ~/server.conf
echo "user=$remote_db_user" >> ~/server.conf
echo "password=$remote_db_pass" >> ~/server.conf
echo "host=$remote_db" >> ~/server.conf

#. This script needs two files in the same current working directory.
#  One is for the list of databases to compress and the other one is to
#  list all the tables to be compressed across those databases. The
#  following command creates the "databases" file.
#. Override the log file generated in previous runs, just to make this
#  script idempotent.
echo "####################################################################" > comparison.log
/bin/echo "show databases" | /usr/bin/mysql --defaults-extra-file=~/server.conf | /bin/grep -Ev "(^Database|common_schema|sys|mysql|performance_schema|information_schema|tmp)$" > databases
databases=$(cat databases)
for database in ${databases[*]}; do
  #. The following command creates the file with the list of all the tables
  #  in the compression candidate database.
  /bin/echo "use $database; show tables;" | /usr/bin/mysql --defaults-extra-file=~/server.conf > tables
  tables=$(cat tables)
  echo "####################################################################" >> comparison.log
  for table in ${tables[*]}; do
    echo "Size of { $database/$table } before compression is: $(du -sh $mysql_data_dir/$database/$table.ibd | awk '{print $1}')" | tee -a comparison.log
    echo "compressing { $table } for { $database }"
    mysql -u $remote_db_user -h $remote_db -p$remote_db_pass -e "use $database;ALTER TABLE $table ROW_FORMAT=COMPRESSED;" >> comparison_errors.log 2>&1
    echo "Size of { $database/$table } after compression is: $(du -sh $mysql_data_dir/$database/$table.ibd | awk '{print $1}')" | tee -a comparison.log
  done
  echo "####################################################################" >> comparison.log
done

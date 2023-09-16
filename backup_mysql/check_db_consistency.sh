#!/bin/bash

check_consistency() {

remote_db=""
remote_db_port="3306"
remote_db_user=""
remote_db_pass=""

echo "[client]" > ~/remote_server.conf
echo "user=$remote_db_user" >> ~/remote_server.conf
echo "password=$remote_db_pass" >> ~/remote_server.conf
echo "host=$remote_db" >> ~/remote_server.conf

local_db="localhost"
local_db_port="3306"
local_db_user=""
local_db_pass=""

echo "[client]" > ~/local_server.conf
echo "user=$local_db_user" >> ~/local_server.conf
echo "password=$local_db_pass" >> ~/local_server.conf
echo "host=$local_db" >> ~/local_server.conf

candidates=$(/bin/echo "show databases" | /usr/bin/mysql --defaults-extra-file=~/remote_server.conf |  /bin/grep -Ev "^(Database|sys|mysql|performance_schema|information_schema)$")
for candidate in ${candidates[*]}; do
  echo "checking... the database { $candidate }"
  tables=$(/bin/echo "use \`$candidate\`;show tables;" | /usr/bin/mysql --defaults-extra-file=~/remote_server.conf | /bin/grep -Ev "^(Tables_in_$candidate|table)$")
  for table in ${tables[*]}; do
    count_rds_server=$(/bin/echo "use \`$candidate\`;select count(*) from \`$table\`;" | /usr/bin/mysql --defaults-extra-file=~/remote_server.conf | sed -n 2p)
    count_local_server=$(/bin/echo "use \`$candidate\`;select count(*) from \`$table\`;" | /usr/bin/mysql --defaults-extra-file=~/local_server.conf | sed -n 2p)
    if [[ $count_rds_server != $count_local_server ]]; then
      echo "the backup/restore is inconsistent."
      echo "current rds _ server count for [ $table ] @ { $candidate } is: ( $count_rds_server )" | tee -a ~/consistency.log
      echo "current local server count for [ $table ] @ { $candidate } is: ( $count_local_server )" | tee -a ~/consistency.log
    else
      echo "database {$candidate} table [ $table ] ...... OK"
    fi
  done
done
}

check_consistency

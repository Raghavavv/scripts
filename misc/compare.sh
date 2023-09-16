#!/bin/bash

db_config_file=""
ls /var/sites/ | grep 'bizom.in' | cut -d'.' -f1 > code
mysql --defaults-extra-file=$db_config_file -e 'show databases' | grep 'bizom_in_bizom' | cut -d'_' -f1 > db
code_exists=$(diff code db | grep '<' | awk '{print $2}')
db_exists=$(diff code db | grep '>' | awk '{print $2}')

check_db(){
  #. $1 => code directory name
  mysql --defaults-extra-file=$db_config_file -e 'show databases' | grep 'bizom_in_bizom' | cut -d'_' -f1 | grep $1 > /dev/null
  if [[ $(echo $?) != 0 ]]; then
    echo "database for code { $1 } does not exists"
    #echo "$1"
  fi
}

check_code(){
  #. $1 => database name
  ls /var/sites/ | grep 'bizom.in' | cut -d'.' -f1 | grep $1 > /dev/null
  if [[ $(echo $?) != 0 ]]; then
    echo "code for database { $1 } does not exists"
    #echo "$1"
  fi
}

for code_exist in ${code_exists[*]}; do
  check_db "$code_exist"
done

for db_exist in ${db_exists[*]}; do
  check_code "$db_exist"
done

#!/bin/bash

db_host="reports.czhlbhy5jjhh.ap-southeast-1.rds.amazonaws.com"
db_user="sys_dump_backup"
db_pass=""
s3_region="ap-southeast-1"
s3_bucket="files.mobisy.com/backup"
random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
timestamp=$(date +'%Y_%m_%d')
tag=${timestamp}_${random}

dump(){
  mysqldump -v --column-statistics=0 --log-error=$dump_dir/error.log --ignore-table=$1.cube_calls --ignore-table=$1.cube_orders --ignore-table=$1.cube_orderdetails --ignore-table=$1.cube_org_hierarchy --ignore-table=$1.cube_paymentdetails --ignore-table=$1.cube_payments --ignore-table=$1.cube_sku --max_allowed_packet=1024M --force --routines --quick --single-transaction=TRUE -h $db_host -u $db_user -p$db_pass $1 > $dump_dir/${1}.sql
  sleep 5
  echo "Dump size: $(du -sh $dump_dir/${1}.sql | awk '{print $1}')" >> $dump_dir/email.txt
}

compress(){
  cd $dump_dir && tar -zcvf ${1}_${tag}.tar.gz ${1}.sql
  sleep 5
  echo "Archive size: $(du -sh $dump_dir/${1}_${tag}.tar.gz | awk '{print $1}')" >> $dump_dir/email.txt
}

upload(){
  aws s3 cp $dump_dir/${1}_${tag}.tar.gz s3://$s3_bucket/
  echo "Download link: http://$s3_bucket/${1}_${tag}.tar.gz"$'\n' | tee -a $dump_dir/email.txt
}

cleanup(){
  rm -f $dump_dir/*.sql $dump_dir/*.tar.gz
}

for db in $@; do
  database=${db}_bizom_in_bizom
  echo "$1"
  dump_dir="/mnt/efs/fs1/$1"
  mkdir -p $dump_dir
  echo "dumping the database $database"
  dump $database
  echo "compressing the database $database"
  compress $database
  echo "uploading the compressed database $database to S3"
  upload $database
  echo "cleaning up the dump from the localhost"
  cleanup
done

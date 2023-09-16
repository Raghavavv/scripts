#!/bin/bash

db_host=""
db_user=""
db_pass=""
dump_dir="/mnt/companies"
s3_region="ap-southeast-1"
s3_bucket="files.mobisy.com/churn_test_gaurav"
random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
timestamp=$(date +'%Y_%m_%d')
tag=${timestamp}_${random}
mkdir -p $dump_dir 

dump(){
  mysqldump -v --log-error=$dump_dir/error.log --max_allowed_packet=1024M --force --routines --quick --single-transaction=TRUE -h $db_host -u $db_user -p$db_pass $1 > $dump_dir/${1}.sql
}

compress(){
  cd $dump_dir && tar -zcvf ${1}_${tag}.tar.gz ${1}.sql
}

upload(){
  aws s3 cp $dump_dir/${1}_${tag}.tar.gz s3://$s3_bucket/
}

cleanup(){
  rm -f $dump_dir/*.sql $dump_dir/*.tar.gz
}

for db in $@; do
  database=${db}_bizom_in_bizom
  echo "dumping the database $database"
  dump $database
  echo "compressing the database $database"
  compress $database
  echo "uploading the compressed database $database to S3"
  upload $database
  echo "cleaning up the dump from the localhost"
  cleanup
done

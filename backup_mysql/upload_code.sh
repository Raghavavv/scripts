#!/bin/bash

s3_region=""
s3_bucket="files.mobisy.com/churn_test_gaurav"
random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
timestamp=$(date +'%Y_%m_%d')
code_dir="/var/sites"
tag=${timestamp}_${random}

compress(){
  cd $code_dir && tar -zcvf ${1}_${tag}.tar.gz ${1}
}

upload(){
  aws s3 cp $code_dir/${1}_${tag}.tar.gz s3://$s3_bucket/
}

cleanup(){
  rm -f $code_dir/${1}_${tag}.tar.gz
}

for db in $@; do
  database=${db}.bizom.in
  echo "compressing the database $database"
  compress $database
  echo "uploading the compressed database $database to S3"
  upload $database
  echo "cleaning up the code from the localhost"
  cleanup $database
done

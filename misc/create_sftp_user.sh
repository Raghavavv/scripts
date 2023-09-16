#!/bin/bash

#. Usage: "sftp.sh <company_name>"
#######################################################################
#. This script needs the following IAM permissions:
#  1. folder creation permission inside a S3 bucket.
#  2. create IAM policy and IAM role.
#  3. create secrets permission in AWS secretsmanager.
#######################################################################

#company="testing"
s3_bucket="integrationftp.bizom.in"

create_s3(){
  #. $1 => company name
  mkdir -p company/$1/bizom && date > company/$1/bizom/creation_timestamp
  aws s3 cp company s3://$s3_bucket/ --recursive
  rm -rf company
}

create_iam(){
  #. $1 => company name
cat <<EOF > $1.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:DeleteObjectVersion",
                "s3:GetObjectVersionAcl",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::$s3_bucket",
                "arn:aws:s3:::$s3_bucket/$1/*"
            ]
        }
    ]
}
EOF
  echo "creating the IAM policy for new company"
  aws iam create-policy --policy-name s3_access_sftp_$1 --policy-document file://$1.json
  rm -f $1.json
  
cat <<EOF > $1.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  echo "creating new IAM role for new company"
  aws iam create-role --role-name sftp-$1 --assume-role-policy-document file://$1.json
  rm -f $1.json
  echo "attaching the IAM policy to the newly created role"
  aws iam attach-role-policy --role-name sftp-$1 --policy-arn arn:aws:iam::596849958460:policy/s3_access_sftp_$1
}

create_secrets(){
  #. $1 => company name
  password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
  echo "{\"Password\":\"$password\",\"Role\":\"arn:aws:iam::596849958460:role/sftp-$1\",\"HomeDirectory\":\"/$s3_bucket/$1\",\"HomeBucket\":\"$s3_bucket\",\"HomeFolder\":\"$1\"}" > credentials.json
  echo "creating the secrets in the secrets mananger"
  aws secretsmanager create-secret --name SFTP/$1 --description "SFTP credentials for the $1." --secret-string file://credentials.json
  echo "SFTP password for company { $1 } is { $password }"
  rm -f credentials.json
}

send_email(){
  #. $1 => company name
  echo "sending the credentials via email."
  echo "Username: $1 || Password: $password || endpoint: $s3_bucket" | mailx -s "{ $1 } SFTP Credentials" -a "From: no-reply@bizom.in" 'devops@mobisy.com'
}

for company in $@; do
  create_s3 $company
  create_iam $company
  create_secrets $company
  send_email $company
done

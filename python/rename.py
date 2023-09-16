#!/usr/bin/python3

import boto3
from pprint import pprint

client = boto3.client('s3')
bucket = '' # Name of the bucket

def main():
  response = client.list_objects(Bucket=bucket)
  #. uncomment the following line, if you need to rename the files
  #  inside a folder which is inside the bucket. Replace the 'Prefix'
  #  string to the common name in all the files, which you want to
  #  rename. Also, remember at the time of writing this code amazon API
  #  returns only 1000 records. Hence if you want to rename more than
  #  1000 objects, you need to run this script in a loop. For example,
  #  in order to rename 40000 objects, we need to run this script 40
  #  times. Here is the bash loop which does this:

    #!/bin/bash
    #i="0"
    #while [ $i -lt 40 ];do
    #  python3 ~/rename.py
    #  i=$[$i+1]
    #  echo "This is $i -th loop."
    #  sleep 2
    #done 

  #response = client.list_objects(Bucket=bucket, Prefix='910/ANCHOR_HEALTH_&amp')
  for obj in response['Contents']:
    if '&amp;' in obj['Key']:
      #pprint(obj['Key'])
      old_key_name = obj['Key']
      new_key_name = old_key_name.replace('&amp;','&')
      pprint('copying {'+old_key_name+'} to {'+new_key_name+'}')
      client.copy_object(Bucket=bucket, CopySource=bucket+'/'+old_key_name, Key=new_key_name)
      pprint('deleting {'+old_key_name+'}')
      client.delete_object(Bucket=bucket, Key=old_key_name)
      #break

if __name__ == "__main__":
  main()

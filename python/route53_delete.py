#!/usr/bin/python3

import json
import boto3
from sys import argv
from pprint import pprint

rows = []
logfile = "./deleted_urls.json"
client = boto3.client('route53')
response = client.list_hosted_zones()
blacklist = ["",""]

def routing():
  #. Change this DNS to the zone from which you want to delete the
  #  record set entries.
  record_set_name = 'bizom.in.'
  for hosted_zone in response['HostedZones']:
    if record_set_name in hosted_zone['Name']:
      for endpoint in argv:
        if endpoint not in blacklist:
          response1 = client.list_resource_record_sets(HostedZoneId = hosted_zone['Id'].split('/')[2], StartRecordName = endpoint, MaxItems = '1')
          for name in response1['ResourceRecordSets']:
            delete_records(endpoint, hosted_zone['Id'].split('/')[2], name['Type'], name['TTL'], name['ResourceRecords'])
            temp = { "url" : endpoint }
            rows.append(json.dumps(temp))
            write_file(rows)

def delete_records(record_name, hosted_zone_id, record_type, record_ttl=None, record_value = [], *args):
  response = client.change_resource_record_sets(
    HostedZoneId = hosted_zone_id,
    ChangeBatch = {
      'Changes': [
        {
          'Action': 'DELETE',
          'ResourceRecordSet': {
            'Name': record_name,
            'Type': record_type,
            'TTL': record_ttl,
            'ResourceRecords': record_value
          }
        }
      ]
    }
  )
  pprint(response)
  return response

def write_file(rows = [], *args):
  f = open(logfile, "w")
  for row in rows:
    f.write(row + "\n")
  f.close()

def main():
  routing()

if __name__ == "__main__":
  main()

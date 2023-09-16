#!/usr/bin/python3

import json
import boto3
import requests
from pprint import pprint

client = boto3.client('route53')
response = client.list_hosted_zones()
rows = []

def routing():
  record_set_name = 'bizom.in.'
  for hosted_zone in response['HostedZones']:
    if record_set_name in hosted_zone['Name']:
      while record_set_name != 'zircon.bizom.in.':
        response1 = response_get(hosted_zone['Id'],record_set_name)
        for name in response1['ResourceRecordSets']:
          try:
            check_status(name['Name'], hosted_zone['Id'], name['Type'], name['TTL'], name['ResourceRecords'])
            record_set_name = name['Name']
          except KeyError:
            pprint('key error has been occured')
            pass
            #name['TTL']=None
        write_file(rows)

def check_status(endpoint, hosted_zone_id, record_type, record_ttl, record_value = [], *args):
  if endpoint[:1] == '_' or 'domainkey' in endpoint:
    pprint('not a valid url')
  else:
    response_http = response_http_get(endpoint)
    try:
      if response_http.status_code == 404 and 'staging' in endpoint:
        temp = { "url" : endpoint, "status_code" : response_http.status_code }
        rows.append(json.dumps(temp))
        pprint('{} {:>5}'.format(endpoint, response_http.status_code))
        pprint('deleting the endpoint')
        pprint(endpoint)
        #delete_records(endpoint, hosted_zone_id.split('/')[2], record_type, record_ttl, record_value)
    except AttributeError as e:
      pprint('exception occured for : ' + endpoint)
      pass

def write_file(rows = [], *args):
  f = open("/tmp/status_code.txt", "w")
  for row in rows:
    f.write(row + "\n")
  f.close()

def response_get(hosted_zone_id,start_record):
  response2 = client.list_resource_record_sets(HostedZoneId=hosted_zone_id,StartRecordName=start_record)
  return response2

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

def response_http_get(endpoint):
  try:
      try:
        response3 = requests.get('http://'+endpoint, timeout=3)
        return response3
      except requests.exceptions.ConnectionError as e:
        pprint('exception occured for : ' + endpoint)
        pass
      except AttributeError as e:
        pprint('exception occured for : ' + endpoint)
        pass
      except requests.exceptions as e:
        pprint('exception occured for : ' + endpoint)
        pass
      except urllib3.exceptions.ReadTimeoutError as e:
        pprint('exception occured for : ' + endpoint)
        pass
      except Exception as e:
        pprint('exception occured for : ' + endpoint)
        pass
  except:
    pprint('http://'+endpoint)

def main():
  routing()

if __name__ == "__main__":
  main()

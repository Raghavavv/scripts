#!/usr/bin/python3

import json
import boto3
import requests
from pprint import pprint

rows = []
client = boto3.client('route53')
response = client.list_hosted_zones()

def routing():
  # "record_set_name" varible contains the DNS name of the zone. Change
  # it if you want to run this code for another zone other than
  # "bizom.in.".
  record_set_name = 'bizom.in.'
  for hosted_zone in response['HostedZones']:
    if record_set_name in hosted_zone['Name']:
      # Loop, till the last record set entry of the zone. Change it if
      # you have done any changes to "record_set_name". 
      while record_set_name != 'zircon.bizom.in.':
        response1 = response_get(hosted_zone['Id'],record_set_name)
        for name in response1['ResourceRecordSets']:
          try:
            check_status(name['Name'])
            record_set_name = name['Name']
          except KeyError:
            pprint('key error has been occured')
            pass
        write_file(rows)

def check_status(endpoint):
  if endpoint[:1] == '_' or 'domainkey' in endpoint:
    pprint('not a valid url')
  else:
    try:
      response_http = response_http_get(endpoint)
      temp = { "url" : endpoint, "status_code" : response_http.status_code }
      rows.append(json.dumps(temp))
      pprint('{} {:>5}'.format(endpoint, response_http.status_code))
    except AttributeError as e:
      pprint('exception occured for : ' + endpoint)
      pass

def write_file(rows = [], *args):
  f = open("./status_codes.json", "w")
  for row in rows:
    f.write(row + "\n")
  f.close()


def response_get(hosted_zone_id,start_record):
  response2 = client.list_resource_record_sets(HostedZoneId=hosted_zone_id,StartRecordName=start_record)
  return response2


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

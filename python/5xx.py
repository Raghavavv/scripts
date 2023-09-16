#!/usr/bin/python3

import os
import json
import time
import boto3
from pprint import pprint
from tabulate import tabulate

client = boto3.client('athena')
athena_database = '' # Name of the Athena database to query
output_location = '' # S3 bucket url to store the results
query_string = 'SELECT request_url, count(*) FROM logs WHERE year = ' + "'%s'" % time.strftime('%Y') + ' AND month = ' + "'%s'" % time.strftime('%m') + ' AND day = ' + "'%s'" % time.strftime('%d') + ' AND target_status_code >= ' + "'%s'" % 500 + ' AND request_url LIKE ' + "'%s'" % '%' + ' GROUP BY request_url ORDER BY count(*) desc'

def query_create():
  response = client.create_named_query(
    Name='5xx_errors_count',
    Description='5xx',
    Database=athena_database,
    QueryString=query_string
  )
  return response['NamedQueryId']

def query_execute():
  execute_query = client.start_query_execution(
    QueryString=query_string,
    QueryExecutionContext={
      'Database': athena_database
    },
    ResultConfiguration={
      'OutputLocation': output_location
    }
  )
  return execute_query['QueryExecutionId']

def query_status(query_execution_id):
  while True:
    status = client.get_query_execution(QueryExecutionId=query_execution_id)
    if status['QueryExecution']['Status']['State'] == 'SUCCEEDED':
      pprint('Query is successful. fetching the results...')
      query_results(query_execution_id)
      break
    else:
      pprint('Waiting for the query {' + query_execution_id + '} to succeed')
      time.sleep(1)
      continue

def query_results(query_execution_id):
  result = client.get_query_results(QueryExecutionId=query_execution_id)
  rows = []
  #rows.append('Link to full results: output_location+'/'+5xx_errors_count/'+time.strftime('%Y')+'/'+time.strftime('%m')+'/'+time.strftime('%d')+'/'+"%s" % query_execution_id+'.csv')
  #rows.append('Query Executed: ' + query_string)
  for data in result['ResultSet']['Rows']:
    row='{:5>}{:>5}'.format(data['Data'][0]['VarCharValue'], data['Data'][1]['VarCharValue'])
    rows.append(row)
  pprint('saving the results to local file-system')
  write_file(rows)

def write_file(rows = [], *args):
  f = open("/tmp/test.txt", "w")
  for row in rows:
    f.write(row + "\n")

def email():
  pprint('Sending the results to email-id')
  command = os.popen('cat /tmp/test.txt | mailx -s "Athena Daily 5XX Alerts" -a "From: no-reply@bizom.in" "gaurav.rajput@mobisy.com,bhupendra@mobisy.com"')

def query_delete(named_query_id):
  pprint('deleting the query from Athena')
  response = client.delete_named_query(NamedQueryId=named_query_id)

def main():
  #named_query_id = query_create()
  query_execution_id = query_execute()
  query_status(query_execution_id)
  email()
  #query_delete(named_query_id)

if __name__ == "__main__":
  main()

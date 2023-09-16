#!/usr/bin/python3

import sys
import boto3
from pprint import pprint

client = boto3.client('ec2')

def main():
  try:
    if sys.argv[2] == 'ankit':
      instance_id = 'i-021c1be435f603370'
      if sys.argv[1] == 'start':
        pprint("starting the node { ankit }")
        start = lambda instance_id: client.start_instances(InstanceIds=[instance_id],)
        start(instance_id)
      else:
        pprint("stopping the node { ankit }")
        stop = lambda instance_id: client.stop_instances(InstanceIds=[instance_id],)
        stop(instance_id)
    elif sys.argv[2] == 'rohit':
      instance_id = 'i-08a7260275464fc66'
      if sys.argv[1] == 'start':
        pprint("starting the node { rohit }")
        start = lambda instance_id: client.start_instances(InstanceIds=[instance_id],)
        start(instance_id)
      else:
        pprint("stopping the node { rohit }")
        stop = lambda instance_id: client.stop_instances(InstanceIds=[instance_id],)
        stop(instance_id)
    else:
      pprint("Usage: python3 startstop.py <start|stop> <ankit|rohit>")
  
  except:
    IndexError
    pprint("Usage: python3 startstop.py <start|stop> <ankit|rohit>")

if __name__ == "__main__":
  main()

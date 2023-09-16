#!/bin/bash
region=""
sns_topic=""

create_alarm(){
  # $1 => resource name
  # $2 => metric name
  # $3 => namespace
  # $4 => dimensions
  # $5 => sns topic
  echo "creating alarm for { $1 } AWS resource"
  aws cloudwatch put-metric-alarm \
    --alarm-name cpu-mon-$(sed 's/\ /_/g' <<<"$1") \
    --alarm-description "Alarm when CPU exceeds 70 percent" \
    --metric-name $2 \
    --namespace $3 \
    --statistic Average \
    --period 300 \
    --threshold 70 \
    --comparison-operator GreaterThanThreshold \
    --dimensions "$4" \
    --evaluation-periods 2 \
    --alarm-actions $5 \
    --unit Percent \
    --region $region
}

rds_alarm(){
  for db_instance in $(aws rds describe-db-instances --region $region | jq -r .DBInstances[].DBInstanceIdentifier); do
    create_alarm "$db_instance" "CPUUtilization" "AWS/RDS" "Name=DBInstanceIdentifier,Value=$db_instance" "$sns_topic"
  done
}

ec2_alarm(){
  instances_id=$(aws ec2 describe-instances --region $region | jq -r .Reservations[].Instances[].InstanceId)
  for instance_id in ${instances_id[*]}; do
    instance_name=$(aws ec2 describe-tags --region $region --filters "Name=resource-id,Values=$instance_id" | jq -r .Tags[].Value)
    create_alarm "$instance_name" "CPUUtilization" "AWS/EC2" "Name=InstanceId,Value=$instance_id" "$sns_topic"
  done
}

rds_alarm
ec2_alarm

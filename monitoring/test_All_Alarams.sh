#!/bin/bash
region=""
sns_topic=""
## bellow array is only for EC2 and RDS which shares same metrics.
alarm_name_cmd=(cpu-mon mem-used mem-avail mem-util mem-used disk-space-util disk-space-avail disk-space-used swap-util swap-used)
metric_name=(CPUUtilinotion )
create_alarm(){
  # $1 => resource name
  # $2 => metric name
  # $3 => namespace
  # $4 => dimensions
  # $5 => sns topic
  echo "creating alarm for { $1 } AWS resource"
  aws cloudwatch put-metric-alarm \
    --alarm-name $met-$(sed 's/\ /_/g' <<<"$1") \
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
 for met_name in $metric_name[*]; do
  for met in $alarm_name_cmd[*]; do
   for db_instance in $(aws rds describe-db-instances --region $region | jq -r .DBInstances[].DBInstanceIdentifier); do
     create_alarm "$db_instance" "$met_name" "AWS/RDS" "Name=DBInstanceIdentifier,Value=$db_instance" "$sns_topic"
   done
  done
 done
}

ec2_alarm(){
 for met_name in $metric_name[*]; do
  for met in $alarm_name_cmd[*]; do
    instances_id=$(aws ec2 describe-instances --region $region | jq -r .Reservations[].Instances[].InstanceId)
   for instance_id in ${instances_id[*]}; do
       instance_name=$(aws ec2 describe-tags --region $region --filters "Name=resource-id,Values=$instance_id" | jq -r .Tags[].Value)
       create_alarm "Alram_name""$instance_name" "$met_name" "AWS/EC2" "Name=InstanceId,Value=$instance_id" "$sns_topic"
   done
  done
 done
}
elb_alarm(){
ELB_Metric=()
  for elb_instance in $(aws elb describe-tags --region $region | jq -r .ELBInstances[].ELBInstanceIdentifier); do
    create_alarm "$elb_instance" "CPUUtilization" "AWS/ApplicationELB" "Name=ELBInstanceIdentifier,Value=$elb_instance" "$sns_topic"
  done
}
rds_alarm
ec2_alarm
elb_alarm

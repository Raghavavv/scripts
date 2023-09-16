#!/bin/bash

environment="dev"
namespace="appmetrics"

access_service_port="9090"
ell_port="8080"
generic_outlet_service_port="9093"
notification_consumer_port="8080"
notification_producer_port="8080"
retailer_module_port="9092"

create_json_payload(){
  #. $1 => The name of the metric
  #. $2 => The value of the metric
  #. $3 => The name of the service
  #. $4 => The unit of the metric
  #. Populate the metric.json file.
  cat <<EOF > ./metric.json
        [
          {
            "MetricName": "$1",
            "Dimensions": [ { "Name": "environment", "Value": "$environment" },
                            { "Name": "service", "Value": "$3" } ],
            "Value": $2,
            "Unit": "$4"
          }
        ]
EOF
}

publish_metric(){
  #. $1 => the name of the published metric
  #. $2 => the value of the metric
  #. $3 => the name of service
  create_json_payload "$1" "$2" "$3" "Count"
  echo "$(date) :: publishing metric { $1 } to cloudwatch"
  aws cloudwatch put-metric-data --namespace $namespace/$environment --metric-data file://metric.json
}

while true; do
  #1. access-service actuator endpoints
  #####################################################################
  [[ "$(curl -s access-service.$environment:$access_service_port/actuator/health | jq -r .status)" == "UP" ]] && publish_metric "access_service_actuator_status" "0" "access-service" || publish_metric "access_service_actuator_status" "1" "access-service"
  #####################################################################

  #2. ell actuator endpoints
  #####################################################################
  [[ "$(curl -s ell.$environment:$ell_port/actuator/health | jq -r .details.ellActuator.status)" == "UP" ]] && publish_metric "ell_actuator_status" "0" "ell" || publish_metric "ell_actuator_status" "1" "ell"
  [[ "$(curl -s ell.$environment:$ell_port/actuator/health | jq -r .details.amazonS3ServiceActuator.status)" == "UP" ]] && publish_metric "s3_actuator_status" "0" "ell" || publish_metric "s3_actuator_status" "1" "ell"
  [[ "$(curl -s ell.$environment:$ell_port/actuator/health | jq -r .details.authServiceActuator.status)" == "UP" ]] && publish_metric "auth_actuator_status" "0" "ell" || publish_metric "auth_actuator_status" "1" "ell"
  [[ "$(curl -s ell.$environment:$ell_port/actuator/health | jq -r .details.clientConfigServer.status)" == "UP" ]] && publish_metric "config_actuator_status" "0" "ell" || publish_metric "config_actuator_status" "1" "ell"
  #####################################################################

  #3. generic-outlet-service actuator endpoints
  #####################################################################
  [[ "$(curl -s generic-outlet-service.$environment:$generic_outlet_service_port/actuator/health | jq -r .status)" == "UP" ]] && publish_metric "generic_outlet_service_actuator_status" "0" "generic-outlet-service" || publish_metric "generic_outlet_service_actuator_status" "1" "generic-outlet-service"
  #####################################################################

  #4. notification-consumer actuator endpoints
  #####################################################################
  [[ "$(curl -s notification-consumer.$environment:$notification_consumer_port/actuator/health | jq -r .details.notificationConsumerActuator.details.S3)" == "UP" ]] && publish_metric "s3_actuator_status" "0" "notification-consumer" || publish_metric "s3_actuator_status" "1" "notification-consumer"
  [[ "$(curl -s notification-consumer.$environment:$notification_consumer_port/actuator/health | jq -r .details.notificationConsumerActuator.details.SES)" == "UP" ]] && publish_metric "ses_actuator_status" "0" "notification-consumer" || publish_metric "ses_actuator_status" "1" "notification-consumer"
  [[ "$(curl -s notification-consumer.$environment:$notification_consumer_port/actuator/health | jq -r .details.clientConfigServer.status)" == "UP" ]] && publish_metric "config_actuator_status" "0" "notification-consumer" || publish_metric "config_actuator_status" "1" "notification-consumer"
  #####################################################################

  #5. notification-producer actuator endpoints
  #####################################################################
  [[ "$(curl -s notification-producer.$environment:$notification_producer_port/actuator/health | jq -r .details.notificationProducerActuator.status)" == "UP" ]] && publish_metric "queue_actuator_status" "0" "notification-producer" || publish_metric "queue_actuator_status" "1" "notification-producer"
  [[ "$(curl -s notification-producer.$environment:$notification_producer_port/actuator/health | jq -r .details.clientConfigServer.status)" == "UP" ]] && publish_metric "config_actuator_status" "0" "notification-producer" || publish_metric "config_actuator_status" "1" "notification-producer"
  [[ "$(curl -s notification-producer.$environment:$notification_producer_port/actuator/health | jq -r .details.amazonS3ServiceActuator.status)" == "UP" ]] && publish_metric "s3_actuator_status" "0" "notification-producer" || publish_metric "s3_actuator_status" "1" "notification-producer"
  #####################################################################

  #6. retailer-module actuator endpoints
  #####################################################################
  [[ "$(curl -s retailer-module.$environment:$retailer_module_port/actuator/health | jq -r .details.amazonS3ServiceActuator.status)" == "UP" ]] && publish_metric "s3_actuator_status" "0" "retailer-module" || publish_metric "s3_actuator_status" "1" "retailer-module"
  [[ "$(curl -s retailer-module.$environment:$retailer_module_port/actuator/health | jq -r .details.clientConfigServer.status)" == "UP" ]] && publish_metric "config_actuator_status" "0" "retailer-module" || publish_metric "config_actuator_status" "1" "retailer-module"
  #####################################################################

  echo "sleeping for 30 seconds..."
  sleep 30
done

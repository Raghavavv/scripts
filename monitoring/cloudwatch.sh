#!/bin/bash

if [[ $(dpkg -l | grep "jq ") ]]; then
  echo "the { json-parser jq } is already installed"
else
  echo "installing the { json-parser jq }"
  sudo apt install -y jq
fi

if [[ $(dpkg -l | grep "awscli") ]]; then
  echo "the { awscli } is already installed"
else
  echo "installing the { awscli }"
  sudo apt install -y awscli
fi

if [ ! -f ~/.aws/credentials ]; then
  echo "aws creadentials are not configured"
  echo "run { aws configure } command to configure the credentials and default region"
  echo "exiting..."
  exit
fi

#. This function calls "create_json" to generate the json file for the
#  metrics publishing. Then it calls the AWS Cloudwatch API to push the
#  metric.
publish_metric(){
  #. $1 => the name of the published metric
  #. $2 => the value of the metric
  #. $3 => the unit of the metric value
  create_json "$1" "$2" "$3"
  echo "$(date) publishing metric { $1 } to cloudwatch"
  aws cloudwatch put-metric-data --namespace "System Usage" --metric-data file://metric.json
}

#. This function creates the json file used in sending the payload to
#  AWS Cloudwatch service. It writes the same file everytime this
#  function is called. Make sure the directory where we are running this
#  script has the write permissions.
create_json(){
  #. $1 => The name of the metric
  #. $2 => The value of the metric
  #. $3 => The unit of the metric
  #. Fetch the instance-id and hostname from the local metadata-service.
  instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
  local_hostname=$(curl -s 169.254.169.254/latest/meta-data/local-hostname)
  #. Populate the metric.json file.
  cat <<EOF > ./metric.json
	[
	  {
	    "MetricName": "$1",
	    "Dimensions": [ { "Name": "Instance id", "Value": "$instance_id" },
	      { "Name": "local hostname", "Value": "$local_hostname" } ],
	    "Value": $2,
	    "Unit": "$3"
	  }
	]
EOF
}

#. Get the system metrics about the java process.
get_process_metric(){
  metrics=("jvm.memory.used"
           "process.cpu.usage"
	   "jvm.buffer.memory.used")
  for metric in ${metrics[@]}; do
    #. The process returns the system resources it is using which is
    #  then parsed with the json parsing tool "jq".
    metric_value=$(curl -s localhost:8080/monitor/systemResources |  jq -r --arg key $metric '.[$key]'.VALUE)
    publish_metric "$metric" "$metric_value" "Count"
  done
}

#. Getting the lag for each database sync.
get_lag(){
  databases=(ids_bizom_in_bizom
    parleagro_bizom_in_bizom
    cargill_bizom_in_bizom
    jyothylabdms_bizom_in_bizom
    nda_bizom_in_bizom
    hri_bizom_in_bizom
    ramdevspices_bizom_in_bizom
    drishti_bizom_in_bizom
    hersheys_bizom_in_bizom
    marsmerchandising_bizom_in_bizom
    mahadhan_bizom_in_bizom)
  for database in ${databases[@]}; do
    #. Get the lag for each database, parse it and remove the extra zero
    #  at the beginning of the values, like 007 minutes => 7 minutes
    db_lag_minutes=$(curl -s localhost:8080/monitor/database/?db=$database | jq -r .LagFromMysqlLastUpdatedTime | cut -d' ' -f1 | sed 's/^0*//')
    #. Convert the lag in minutes into seconds.
    db_lag_seconds=$(( db_lag_minutes * 60 ))
    metric_name=lag_$database
    publish_metric "$metric_name" "$db_lag_seconds" "Seconds"
  done
}

#. Initializing the variables with zero value. These are the initial
#  number of select/update/insert/delete queries.
let old_no_of_select=old_no_of_update=old_no_of_insert=old_no_of_delete=0

#. Get the metrics from the local mysql database. For this function to
#  work we need to put the "server.conf" file inside the home directory
#  of the current user or the user which is running the script. This is
#  because, we do not want to hard code the credentials inside the
#  script.
get_local_db(){
  #. Fetching the lag of the mysql slave from the master server.
  lag=$(mysql --defaults-extra-file=~/.server.conf -e 'show slave status\G' | grep Seconds_Behind_Master | awk '{print $2}')
  #. If the replication gets stopped due to any reason, the "seconds 
  #  behind master" becomes "NULL". In such situation we do not get 
  #  alert. Hence setting the arbitrary value 10000.
  [[ "$lag" == "NULL" ]] && lag=10000
  #. To find the number of select/update/insert/delete queries, we are
  #  quering the mysql database. We are sending the queries in batch so
  #  that we need not run the individual statements. The numbers
  #  returned are the number of queries since last restart.
  queries=($(mysql --defaults-extra-file=~/.server.conf -e 'show global status like "Com_select";show global status like "Com_update";show global status like "Com_insert";show global status like "Com_delete";'))
  #. Finding the no of each queries in the polling interval
  no_of_select=$(( ${queries[3]} - $old_no_of_select ))
  no_of_update=$(( ${queries[7]} - $old_no_of_update ))
  no_of_insert=$(( ${queries[11]} - $old_no_of_insert ))
  no_of_delete=$(( ${queries[15]} - $old_no_of_delete ))
  publish_metric "Seconds_Behind_Master" "$lag" "Seconds"
  publish_metric "Select_queries_per_minute" "$no_of_select" "Count"
  publish_metric "Update_queries_per_minute" "$no_of_update" "Count"
  publish_metric "Insert_queries_per_minute" "$no_of_insert" "Count"
  publish_metric "Delete_queries_per_minute" "$no_of_delete" "Count"
  #. Set up the value for old variable to the new value so that it can
  #  be used in next loop iteration.
  old_no_of_select=${queries[3]}
  old_no_of_update=${queries[7]}
  old_no_of_insert=${queries[11]}
  old_no_of_delete=${queries[15]}
}

#. Running an infinite loop and calling the declared functions serially.
#. The default polling time is 45 seconds because it almost takes 15
#  seconds each time this whole script runs and fetches the different
#  metrics. Hence, the difference between two data points for the same
#  metric is around 60 seconds.
while true; do
  get_process_metric
  get_lag
  get_local_db
  echo "sleeping for 45 seconds"
  sleep 45
done

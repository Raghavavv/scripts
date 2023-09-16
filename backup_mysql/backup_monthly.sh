#!/bin/bash

#. Name of the RDS database, we want to make backup for.
database_name=""
#. Tagging the newly created snapshot with the unix timestamp. It will
#  help us sorting the snapshots list based upon the timestamp
unix_timestamp=$(date +%s)
random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)

#. Created the manual backup for the supplied RDS database by copying
#  the latest snapshot. "aws rds describe-db-snapshots" option returns
#  a sorted list of the snapshots with oldest snapshot on the top. 
#. Hence we are sorting the list of available "automated" backups in
#  the reverse order.
#. Copy the snapshot. Use random string to create unique "target-db-
#  -snapshot-identifier". We are tagging the random string "tihymrb" 
#  to each snapshot created by this script. This is to ensure, we are
#  not going to touch the other manually created backups. If we do not
#  mention such filter then this script will delete the oldest backup,
#  doesn't matter if that backup was created by this script or some
#  user created it manually.
snapshot_copy(){
  latest_snapshot=$(aws rds describe-db-snapshots --snapshot-type automated | jq -r .DBSnapshots[].DBSnapshotIdentifier | grep $database_name | sort -r | sed '1q' | cut -d':' -f2)
  aws rds copy-db-snapshot --source-db-snapshot-identifier "rds:${latest_snapshot}" --target-db-snapshot-identifier "${latest_snapshot}-tihymrb-${unix_timestamp}-${random}"
  #. Wait until the newly created snapshot is available, once it is
  #  available call the snapshot_curation function.
  while [[ $(aws rds describe-db-snapshots --snapshot-type manual --db-snapshot-identifier ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} | jq -r .DBSnapshots[].Status) != "available" ]]; do
    echo "waiting for the snapshot to finish...sleeping for 2 minutes."
    sleep 120
  done
  if [[ $(aws rds describe-db-snapshots --snapshot-type manual --db-snapshot-identifier ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} | jq -r .DBSnapshots[].Status) == "available" ]]; then
    echo "snapshot was successful."
    snapshot_curation "successful"
  else
    echo "snapshot was unsuccessful"
    #snapshot_curation "unsuccessful"
    exit 1
  fi
}

#. Delete the extra snapshot.
snapshot_delete(){
  #. $1 => db-snapshot-identifier
  echo "deleting the snapshot { $1 }"
  aws rds delete-db-snapshot --db-snapshot-identifier $1
}

#. Get the list of "manual" database snapshots.
#. Check if the number of manual snapshots is greater than 6.
#. If the number is greater than 6 than fetch the list of "manual"
#  snapshots and delete the oldest one.
snapshot_curation(){
  #. $1 => status of the snapshot.
  manual_snapshot_count=$(aws rds describe-db-snapshots --snapshot-type manual | jq -r .DBSnapshots[].DBSnapshotIdentifier | grep "^${database_name}-\S*-tihymrb-\S*" | wc -l)
  if [[ $manual_snapshot_count > 6 ]]; then
    echo "Snapshot count is exceeding the 6 months limit. deleting the oldest snapshot"
    db_snapshot_remove=$(aws rds describe-db-snapshots --snapshot-type manual | jq -r .DBSnapshots[].DBSnapshotIdentifier | grep "^${database_name}-\S*-tihymrb-\S*" | head -1)
    snapshot_delete $db_snapshot_remove
    echo "sending the email alert."
    message="monthly backup for $database_name is $1.\nThe newly created snapshot is named: { ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} }.\nMore than 6 months backup available.\nCurated snapshot { $db_snapshot_remove }."
    send_email "$message"
  else
    echo "Less than 6 months backup available. no curation needed."
    echo "sending the email alert."
    message="monthly backup for $database_name is $1.\nThe newly created snapshot is named: { ${latest_snapshot}-tihymrb-${unix_timestamp}-${random} }.\nLess than 6 months backup available, hence no curation needed."
    send_email "$message"
  fi
}

send_email(){
  #. $1 => email message composed in snapshot_curation function.
  echo -e "$1" | mailx -s "monthly RDS backup" -a "From: no-reply@bizom.in" 'devops@mobisy.com'
}

snapshot_copy

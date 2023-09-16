#!/bin/bash

#start date= $1 format of date should be YYYY/MM/DD
#end date= $2 format of date should be YYYY/MM/DD
#Athena table name=$3
#S3 location=$4  must give location up to year folder starts
#(for example actual location s3://bizomlivelogs/bizomprodvpcflowlogs/AWSLogs/596849958460/vpcflowlogs/ap-southeast-1/2022/12/28/
#$4 value s3://bizomlivelogs/bizomprodvpcflowlogs/AWSLogs/596849958460/vpcflowlogs/ap-southeast-1)

#This function delete the partition result file
delete()
{

	rm -rf partitionresult.txt

}

#This function generates athena partition queries  
partition()
{

	startdate=$1
	enddate=$2
	tablename=$3
	location=$4

	startdate=$(date -d $startdate +%Y%m%d)
	enddate=$(date -d $enddate +%Y%m%d)

	i=0

	while [[ $startdate -le $enddate ]]
	do
		year=$(date -d "$startdate" "+%Y")
		month=$(date -d "$startdate" "+%m")
		day=$(date -d "$startdate" "+%d")

		if [[ $i -eq 0 ]]
		then
			query="ALTER TABLE $tablename ADD PARTITION (year='$year', month='$month', day='$day') location '$location/$year/$month/$day/'"
			echo $query >> partitionresult.txt
			let "i+=1"
		else
			query="PARTITION (year='$year', month='$month', day='$day') location '$location/$year/$month/$day/'" 
			echo $query >> partitionresult.txt
		fi
		startdate=$(date -d "$startdate + 1 day" +"%Y%m%d")
	done
	echo ";" >> partitionresult.txt
}

delete
partition $1 $2 $3 $4
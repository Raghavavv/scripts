#!/bin/bash
################################################################
##   /var/log/bizomweblog/app.log Backup To Amazon S3
##   Written By: Raghava V
##   executing using	bash <filename>
##   $crontab -e
##   For every 30min app.log back up to s3
##   */30 * * * * /home/ubuntu/scripts/logs2s3.sh 
################################################################

NOW_DAY=$(date +"%d")
NOW_TIME=$(date +"%Y-%m-%d %T %p")
NOW_YEAR=$(date +"%Y")
NOW_MONTH=$(date +"%m")
ENV_NAME="bizom_dev"

AMAZON_S3_BUCKET="s3://mumbai-bizomweb-logs/$ENV_NAME/$NOW_YEAR/$NOW_MONTH/$NOW_DAY/"

upload_log(){
	array=($(sudo find /var/log/bizomweblog/ -mmin -30 -name 'app.log.*'))
        for i in "${array[@]}"
        do
		backup_files ${i}
		upload_s3 ${i}
		cleanup ${i}

	done
}

backup_files(){
	sudo tar -czf "${1}.gz" --absolute-names "${1}"
}
upload_s3(){
	aws s3 cp "${1}.gz" "${AMAZON_S3_BUCKET}"
}

cleanup(){
        sudo rm -r "${1}.gz"
}

upload_log

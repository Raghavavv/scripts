#!/bin/bash

#This script converts MySQL table data to CSV format and sends this CSV attachment file to mail 

#enter dbhost and dbuser and db_password value
db_host=""
db_user=""
db_password=""

db_connect()
{
	mysql -h $db_host -u $db_user -p$db_password <<EOF
	#change db name
	use bizomsignup;
	#change table name
	select * from cities;
EOF
}

convert_tabledata_to_csv()
 {
	sed "s/\"/\"\"/g;s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" tableresult > tableresult.csv
 }

send_mail()
{
	#change subject and recipient address 
	echo 'PFA' | s-nail -s "Slow log from bizom master DB" --attach=tableresult.csv sateesh.r@mobisy.com
}


remove_file()
{
	rm -rf tableresult tableresult.csv
}

db_connect > tableresult
convert_tabledata_to_csv
send_mail
remove_file
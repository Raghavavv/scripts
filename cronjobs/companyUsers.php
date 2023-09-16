<?php
include_once('database3.php');

/* If you not provide arguments,
 * By Default Current Month and Year
 * Arguments
 * First: Month
 * Second: Year
 */
//Invoicing, GRN, CLaims, inventory management
$writeDB = "bizomapaclbbk.czhlbhy5jjhh.ap-southeast-1.rds.amazonaws.com";
$fromDate = $toDate = date( "Y-m-d" , strtotime('-1 days'));
if( isset( $argv[1]  )  ) {
	$fromDate = $argv[1];
}
if( isset( $argv[2] ) ) {
	$toDate = $argv[2];
}
$fdate = $fromDate;
$tdate = $toDate;
$fromDate .= ' 00:00:00';
$toDate .= ' 23:59:59';
if (empty($month)) {
	$month = date('m');
}
if (empty($year)) {
	$year = date('Y');
}

$tableName = "companyuserswithtransactions";
// $tableName = "companyusers";

//Get Only bizom databases
$db_list = "SHOW DATABASES LIKE '%_bizom'";
$db_list = $db->query( $db_list, FIRSTDB );
$usableDbs = array();
foreach( $db_list as $index => $dbs ) {
	if( strpos( $dbs[0], 'bizom_in_bizom') !== false ) {
			$usableDbs[] = $dbs[0];
	}
}
// pr($usableDbs);
// exit;

//$forId = date( "Y-m-d" , strtotime('-2 days'));
//$getMaxId = "SELECT max(id) as maxId FROM `billing`.`companyuserswithpartition` where fordate = '$forId'";
//$getMaxId = $db->query( $getMaxId, FIRSTDB );
//$maxId = $getMaxId[0][ 'maxId' ];

/* If you want to generate bill for one or countable number of companies then add company name in $exclude array.
 * Remove Not "!" from below line of code "!in_array( $dbs, $exclude )"
 * Else Leave as Default
 */

//$exclude = array( 'parleagro_bizom_in_bizom','usfa_bizom_in_bizom' );

$exclude = array( 'apl1_bizom_in_bizom','apl_bizom_in_bizom','api_bizom_in_bizom','ravi_bizom_in_bizom' ); //Exclude these database names always

// pr( $usableDbs );exit;

/* If some error occurs then use pr( $usableDbs );exit; to get index
 * Exclude index till where execution stoped Database Name using "if( $index <= 50  ) continue;"
 * uncomment line with you index number //if( $index <= 50  ) continue;
 */

foreach( $usableDbs as $index => $dbs ){
	if( !in_array( $dbs, $exclude ) ) {
		// if( $index != 408  ) continue;
		$dbName = $dbs;
		echo $dbName."\n";
		$url = explode( '_', $dbName );
		$companyUrl = $url[0].".bizom.in";
		$query = "SHOW TABLES;";
		$tables = $db->query( $query, $dbName );
		$count = 0;
		foreach( $tables as $key => $table ) {
			if( $table[0] == 'users' ||
				$table[0] == 'manageroles' ||
				$table[0] == 'companies' ||
				$table[0] == 'logs' ||
				$table[0] == 'appversions'
			) {
				$count++;
			}
		}
		if( $count < 5 ) continue;
		//Users
		$query = "SELECT users.id AS user_id,
					   users.username AS username,
					   users.name AS name,
					   users.employeeid as employeeid,
					   users.created,
					   users.inactivedate,
					   dates.date as fordate,
					   week( dates.date ) as 'week',
					   month( dates.date ) as 'month',
					   year( dates.date ) as 'year',
					   YEARWEEK( dates.date ) as 'yearweek',
					   CASE
							   WHEN users.active = 1 AND date( users.created ) <= date( dates.date )
							   THEN 1
							   WHEN users.active = 0 AND date( users.created ) <= date( dates.date ) AND date( users.inactivedate ) > date( dates.date )
							   THEN 1
							   WHEN users.active = 0  AND date( users.created ) <= dates.date AND ( date( users.inactivedate ) <= date( dates.date ) OR date( users.inactivedate ) = date( dates.date ))
							   THEN 3
							   WHEN users.active in ( 1, 0 ) AND date( users.created ) > dates.date
							   THEN 3
							   ELSE 10
							END  as 'status'
		FROM users
		RIGHT JOIN dates on dates.date BETWEEN '$fdate' AND '$tdate'
		WHERE dates.date BETWEEN '$fdate' AND '$tdate'";
		$users = $db->query( $query, $dbName );

		//manageroles
		$query = "SELECT *
		FROM manageroles";
		$manageroles = $db->query( $query, $dbName );
		$userRoles = array();
		foreach( $manageroles as $key => $data ){
			$uid = $data[ 'user_id' ];
			if( !isset( $userRoles[ $uid ] ) ) $userRoles[ $uid ] = $data[ 'role_id' ];
		}
		//Company
		$company = "SELECT      companies.id as company_id,
																						companies.name as company_name
														From companies";
		$company = $db->query( $company, $dbName );
		$companyid = ( isset( $company[ 0 ][ 'company_id' ] )  ? $company[ 0 ][ 'company_id' ] :  0 );
		$companyname = ( isset( $company[ 0 ][ 'company_name' ] )  ? $company[ 0 ][ 'company_name' ] : ' ' );

        // Oneview report and dashboard usage
        $oneviewUsage = "SELECT
                            user_id,
                            date(created) AS fordate,
                            SUM(
                                CASE
                                    WHEN entity_type = 'REPORT' THEN 1
                                    ELSE 0
                                END
                            ) AS oneview_report,
                            SUM(
                                CASE
                                    WHEN entity_type = 'DASHBOARD' THEN 1
                                    ELSE 0
                                END
                            ) AS oneview_dashboard
                        FROM
                            `bizomreports`.`audits`
                        WHERE
                            created >= '$fromDate'
                            AND created <= '$toDate'
                            and company_id in ($companyid)
                        GROUP BY
                            user_id,
                            fordate;";
        $oneviewUsage = $db->query( $oneviewUsage, "bizomreports" );
        $oneviewData = array();
		foreach( $oneviewUsage as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $oneviewData[ $uid ] ) ) $oneviewData[ $uid ] = array();
			if( !isset( $oneviewData[ $uid ][ $fordate ] ) ) $oneviewData[ $uid ][ $fordate ] = array();
			$oneviewData[ $uid ][ $fordate ]['oneview_report'] = $data[ 'oneview_report' ];
			$oneviewData[ $uid ][ $fordate ]['oneview_dashboard'] = $data[ 'oneview_dashboard' ];
		}
		unset( $oneviewUsage );

    
        // Old ell report and dashboard usage
        $oldEllUsage = "SELECT
                            users.bizom_user_id AS user_id,
                            date(accesslogs.created) as fordate,
                            SUM(
                                CASE
                                    WHEN reports.isdashboard = 0 THEN 1
                                    ELSE 0
                                END
                            ) AS oldell_report,
                            SUM(
                                CASE
                                    WHEN reports.isdashboard = 1 THEN 1
                                    else 0
                                END
                            ) AS oldell_dashboard
                        FROM
                            `bizomreports`.`accesslogs`
                            LEFT JOIN users ON users.id = accesslogs.user_id
                            LEFT join reports ON reports.id = accesslogs.report_id
                        WHERE
                            accesslogs.created >= '$fromDate'
                            AND accesslogs.created <= '$toDate'
                            and company_id in ($companyid)
                        GROUP BY
                            users.bizom_user_id,
                            fordate;";
        $oldEllUsage = $db->query( $oldEllUsage, "bizomreports" );
        $oldEllData = array();
		foreach( $oldEllUsage as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $oldEllData[ $uid ] ) ) $oldEllData[ $uid ] = array();
			if( !isset( $oldEllData[ $uid ][ $fordate ] ) ) $oldEllData[ $uid ][ $fordate ] = array();
			$oldEllData[ $uid ][ $fordate ]['oldell_report'] = $data[ 'oldell_report' ];
			$oldEllData[ $uid ][ $fordate ]['oldell_dashboard'] = $data[ 'oldell_dashboard' ];
		}
		unset( $oldEllUsage );

		//App Loign
		$logintoapp = "SELECT   appversions.user_id,
										COUNT( appversions.id ) as app_login_times,
										appversions.fordate
		FROM appversions
		WHERE appversions.fordate BETWEEN '$fdate' AND '$tdate'
		GROUP by appversions.user_id,appversions.fordate";

		$logintoapp = $db->query( $logintoapp, $dbName );
		$logintoappInfo = array();
		foreach( $logintoapp as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $logintoappInfo[ $uid ] ) ) $logintoappInfo[ $uid ] = array();
			if( !isset( $logintoappInfo[ $uid ][ $fordate ] ) ) $logintoappInfo[ $uid ][ $fordate ] = array();
			$logintoappInfo[ $uid ][ $fordate ] = $data[ 'app_login_times' ];
		}
		unset( $logintoapp );
		//Portal Login
		$logintoportal = "SELECT   logs.user_id,
			date( logs.created ) as fordate,
			url as url
		FROM logs
		WHERE logs.created BETWEEN '$fromDate 00:00:00' AND '$toDate 23:59:59' and action = 'Loginsuccess'";
		$logintoportal = $db->query( $logintoportal, $dbName );
		$loginInfo = array();
		foreach( $logintoportal as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			$url = $data[ 'url' ];
			if( !isset( $loginInfo[ $uid ] ) ) $loginInfo[ $uid ] = array();
			if( !isset( $loginInfo[ $uid ][ $fordate ] ) ) $loginInfo[ $uid ][ $fordate ] = array( "portal" => 0, "mobile" => 0, "report" => 0 );
			if( $url == '/users/login' ) {
							$loginInfo[ $uid ][ $fordate ][ 'portal' ]++;
			}
			if( $url == '/users/pdalogin' ) {
							$loginInfo[ $uid ][ $fordate ][ 'mobile' ]++;
			}
			if( $url == '//users/saveReportsLoginLog' ) {
							$loginInfo[ $uid ][ $fordate ][ 'report' ]++;
			}
		}
		unset( $logintoportal );

		//attendances
		$attendances = "SELECT 	attendances.user_id,
				COUNT( attendances.id ) as 'attendances',
				attendances.fordate
		FROM attendances
		WHERE attendances.fordate BETWEEN '$fdate' AND '$tdate'
		GROUP by attendances.user_id,attendances.fordate";
		$attendances = $db->query( $attendances, $dbName );
		$attendanceInfo = array();
		foreach( $attendances as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $attendanceInfo[ $uid ] ) ) $attendanceInfo[ $uid ] = array();
			if( !isset( $attendanceInfo[ $uid ][ $fordate ] ) ) $attendanceInfo[ $uid ][ $fordate ] = array();
			$attendanceInfo[ $uid ][ $fordate ] = $data[ 'attendances' ];
		}
		unset( $attendances );

		//activities
		$activities = "SELECT 	activities.user_id,
				COUNT( activities.id ) as 'activities',
				date( activities.fordate ) as 'fordate'
		FROM activities
		WHERE activities.fordate BETWEEN '$fdate 00:00:00' AND '$tdate 23:59:59' AND activities.activitytype_id not in (  1,7,2,10 )
		GROUP by activities.user_id,date( activities.fordate )        ";
		$activities = $db->query( $activities, $dbName );
		$activitieInfo = array();
		foreach( $activities as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $activitieInfo[ $uid ] ) ) $activitieInfo[ $uid ] = array();
			if( !isset( $activitieInfo[ $uid ][ $fordate ] ) ) $activitieInfo[ $uid ][ $fordate ] = array();
			$activitieInfo[ $uid ][ $fordate ] = $data[ 'activities' ];
		}
		unset( $activities );

		//Free
		$signup = "SELECT       bizomsignup.users.username AS username,
                                isfree as isfree
                   FROM bizomsignup.users
                   where bizomsignup.users.company_id = $companyid";
        $signup = $db->query( $signup, $dbName );
		$signupInfo = array();
		foreach( $signup as $key => $data ){
			$userName = $data[ 'username' ];
			if( !isset( $signupInfo[ $userName ] ) ) {
					$signupInfo[ $userName ] = $data[ 'isfree' ];
			}
		}
		unset( $signup );

		//orders
		$orders = "SELECT 	orders.user_id,
				COUNT( orders.id ) as 'orders',
				SUM( orders.amount ) as amt,
				date( orders.fordate ) as 'fordate'
		FROM orders
		WHERE orders.fordate BETWEEN '$fdate 00:00:00' AND '$tdate 23:59:59' and orders.orderstate_id <> 4
		GROUP by orders.user_id,date( orders.fordate )        ";
		$orders = $db->query( $orders, $dbName );
		$orderInfo = array();
		foreach( $orders as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $orderInfo[ $uid ] ) ) $orderInfo[ $uid ] = array();
			if( !isset( $orderInfo[ $uid ][ $fordate ] ) ) $orderInfo[ $uid ][ $fordate ] = array();
			$orderInfo[ $uid ][ $fordate ][ 'orders' ] = $data[ 'orders' ];
			$orderInfo[ $uid ][ $fordate ][ 'amt' ] = $data[ 'amt' ];
		}
		unset( $orders );
		//payments
		$columnQuery = "SHOW COLUMNS FROM `payments` LIKE 'isactive'";
		$columnQuery = $db->query( $columnQuery, $dbName );
		$paymentCondition = '';
		if( !empty( $columnQuery ) ) {
			$paymentCondition = "AND payments.isactive = 1";
		}
		$payments = "SELECT 	payments.user_id,
				COUNT( payments.id ) as 'payments',
				SUM( payments.amount ) as amt,
				date( payments.fordate ) as 'fordate'
		FROM payments
		WHERE payments.fordate BETWEEN '$fdate 00:00:00' AND '$tdate 23:59:59' $paymentCondition
		GROUP by payments.user_id,date( payments.fordate )        ";
		$payments = $db->query( $payments, $dbName );
		$paymentInfo = array();
		foreach( $payments as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $paymentInfo[ $uid ] ) ) $paymentInfo[ $uid ] = array();
			if( !isset( $paymentInfo[ $uid ][ $fordate ] ) ) $paymentInfo[ $uid ][ $fordate ] = array();
			$paymentInfo[ $uid ][ $fordate ][ 'payments' ] = $data[ 'payments' ];
			$paymentInfo[ $uid ][ $fordate ][ 'amt' ] = $data[ 'amt' ];
		}
		unset( $payments );

		//outlets
		$columnQuery = "SHOW COLUMNS FROM `outlets` LIKE 'createdbyuser_id'";
		$columnQuery = $db->query( $columnQuery, $dbName );
		$outletInfo = array();
		if( !empty( $columnQuery ) ) {
			$outlets = "SELECT 	outlets.createdbyuser_id as user_id,
				COUNT( outlets.id ) as 'outlets',
				date( outlets.created ) as 'fordate'
			FROM outlets
			WHERE outlets.created BETWEEN '$fdate 00:00:00' AND '$tdate 23:59:59'
			GROUP by outlets.createdbyuser_id,date( outlets.created )        ";
			$outlets = $db->query( $outlets, $dbName );
			foreach( $outlets as $key => $data ){
				$uid = $data[ 'user_id' ];
				$fordate = $data[ 'fordate' ];
				if( !isset( $outletInfo[ $uid ] ) ) $outletInfo[ $uid ] = array();
				if( !isset( $outletInfo[ $uid ][ $fordate ] ) ) $outletInfo[ $uid ][ $fordate ] = array();
				$outletInfo[ $uid ][ $fordate ] = $data[ 'outlets' ];
			}
			unset( $outlets );
		}

		//pjps
		$columnQuery = "SHOW COLUMNS FROM `pjps` LIKE 'fordate'";
		$columnQuery = $db->query( $columnQuery, $dbName );
		$pjpInfo = array();
		if( !empty( $columnQuery ) ) {
			$pjps = "SELECT 	pjps.user_id,
								pjps.fordate as 'fordate',
								count( DISTINCT beatdetails.outlet_id ) as pjps
			FROM pjps
			JOIN  beatdetails on pjps.beat_id = beatdetails.beat_id
				AND (beatdetails.todate = '0000-00-00 00:00:00'
				OR beatdetails.todate >= '$fdate 00:00:00')
				AND beatdetails.fromdate <= '$tdate 23:59:59'
			WHERE pjps.fordate  BETWEEN '$fdate' AND '$tdate'
			GROUP BY pjps.fordate,pjps.user_id";
			$pjps = $db->query( $pjps, $dbName );
			foreach( $pjps as $key => $data ){
				$uid = $data[ 'user_id' ];
				$fordate = $data[ 'fordate' ];
				if( !isset( $pjpInfo[ $uid ] ) ) $pjpInfo[ $uid ] = array();
				if( !isset( $pjpInfo[ $uid ][ $fordate ] ) ) $pjpInfo[ $uid ][ $fordate ] = array();
				$pjpInfo[ $uid ][ $fordate ] = $data[ 'pjps' ];
			}
			unset( $pjps );
		}

		//claims
		$claims = "SELECT 	claimdetails.user_id,
       			COUNT( DISTINCT claimdetails.claim_id ) as claims,
                claimdetails.fordate as fordate
		FROM claimdetails
		WHERE claimdetails.fordate BETWEEN '$fdate' AND '$tdate'
		GROUP BY claimdetails.user_id,claimdetails.fordate";
		$claims = $db->query( $claims, $dbName );
		$claimInfo = array();
		foreach( $claims as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $claimInfo[ $uid ] ) ) $claimInfo[ $uid ] = array();
			if( !isset( $claimInfo[ $uid ][ $fordate ] ) ) $claimInfo[ $uid ][ $fordate ] = array();
			$claimInfo[ $uid ][ $fordate ] = $data[ 'claims' ];
		}
		unset( $claims );

		//calls
		$calls = "SELECT 	calls.user_id,
       			COUNT( DISTINCT case when calls.pjpoutlet = 1 then calls.outlet_id end ) as calls,
                calls.fordate
		FROM calls
		WHERE calls.fordate BETWEEN '$fdate' AND '$tdate'
		GROUP BY calls.user_id,calls.fordate";
		$calls = $db->query( $calls, $dbName );
		$callInfo = array();
		foreach( $calls as $key => $data ){
			$uid = $data[ 'user_id' ];
			$fordate = $data[ 'fordate' ];
			if( !isset( $callInfo[ $uid ] ) ) $callInfo[ $uid ] = array();
			if( !isset( $callInfo[ $uid ][ $fordate ] ) ) $callInfo[ $uid ][ $fordate ] = array();
			$callInfo[ $uid ][ $fordate ] = $data[ 'calls' ];
		}
		unset( $claims );
        
		$columns = array( 'user_id','company_id','role_id','report_login_times','portal_login_times','app_login_times','isactive','fordate','yearlymonth','yearlyweek','attendances','activities','isfree','orders','orderamount','payments','paymentamount','outlets','pjps','claims','calls', 'oneview_report', 'oneview_dashboard','oldell_report','oldell_dashboard');
		$columns = implode(", ",$columns);
		//Insert Into Table
		$insertValues = array();
		foreach( $users as $key => $user ){
				$insertval = '';
				$status = $user['status'];
				if( $status >= 3 ) continue;
				$userid = ( isset( $user[ 'user_id' ] )  ? $user[ 'user_id' ] :  0 );
				$username = ( isset( $user[ 'username' ] )  ? $user[ 'username' ] :  '' );
				$fordate = ( isset( $user[ 'fordate' ] )  ? $user[ 'fordate' ] :  0 );
				$roleid = ( isset( $userRoles[$userid] ) ? $userRoles[$userid] : 0);
				$year = ( isset( $user[ 'year' ] ) ? $user[ 'year' ] : 0);
				$month = $year ."". ( isset( $user[ 'month' ] ) ? $user[ 'month' ] : 0);
				$week = isset( $user[ 'yearweek' ] ) ? $user[ 'yearweek' ] : 0;
				$calls = $orders = $orderAmt = $payments = $paymentAmt = $outlets = $pjps = $claims = $activity_times = $attendance_times = $isbillable = $price = $isfree = 0;
				$portal_login_times = $app_login_times = $report_login_times = $oneview_report = $oneview_dashboard = $oldell_report = $oldell_dashboard = 0;
				if( isset( $loginInfo[ $userid ][ $fordate ][ "report" ] ) ) {
					$report_login_times = $loginInfo[ $userid ][ $fordate ][ "report" ];
					$isbillable = 1;
				}
				if( isset( $loginInfo[ $userid ][ $fordate ][ "portal" ] ) ) {
					$portal_login_times = $loginInfo[ $userid ][ $fordate ][ "portal" ];
					$isbillable = 1;
				}
				if( isset( $logintoappInfo[ $userid ][ $fordate ] ) ) {
					$app_login_times = $logintoappInfo[ $userid ][ $fordate ];
					$isbillable = 1;
				}
				if( isset( $loginInfo[ $userid ][ $fordate ][ "mobile" ] ) ) {
					$app_login_times += $loginInfo[ $userid ][ $fordate ][ "mobile" ];
					$isbillable = 1;
				}
				if( isset( $loginInfo[ $userid ][ $fordate ][ "mobile" ] ) ) {
					$app_login_times += $loginInfo[ $userid ][ $fordate ][ "mobile" ];
					$isbillable = 1;
				}

                if( isset( $oneviewData[ $userid ][ $fordate ][ "oneview_report" ] ) ) {
					$oneview_report += $oneviewData[ $userid ][ $fordate ][ "oneview_report" ];
					$isbillable = 1;
				}
				if( isset( $oneviewData[ $userid ][ $fordate ][ "oneview_dashboard" ] ) ) {
					$oneview_dashboard += $oneviewData[ $userid ][ $fordate ][ "oneview_dashboard" ];
					$isbillable = 1;
				}

                if( isset( $oldEllData[ $userid ][ $fordate ][ "oldell_report" ] ) ) {
					$oldell_report += $oldEllData[ $userid ][ $fordate ][ "oldell_report" ];
					$isbillable = 1;
				}
                if( isset( $oldEllData[ $userid ][ $fordate ][ "oldell_dashboard" ] ) ) {
					$oldell_dashboard += $oldEllData[ $userid ][ $fordate ][ "oldell_dashboard" ];
					$isbillable = 1;
				}

				if( isset( $attendanceInfo[ $userid ][ $fordate ] ) ) {
					$attendance_times = $attendanceInfo[ $userid ][ $fordate ];
					$isbillable = 1;
				}
				if( isset( $activitieInfo[ $userid ][ $fordate ] ) ) {
					$activity_times = $activitieInfo[ $userid ][ $fordate ];
					$isbillable = 1;
				}
				if( isset( $signupInfo[ $username ] ) ) {
					$isfree = $signupInfo[ $username ];
				}
				if( isset( $orderInfo[ $userid ][ $fordate ] ) ) {
					$orders = $orderInfo[ $userid ][ $fordate ][ 'orders' ];
					$orderAmt = $orderInfo[ $userid ][ $fordate ][ 'amt' ];
				}
				if( isset( $paymentInfo[ $userid ][ $fordate ] ) ) {
					$payments = $paymentInfo[ $userid ][ $fordate ][ 'payments' ];
					$paymentAmt = $paymentInfo[ $userid ][ $fordate ][ 'amt' ];
				}
				if( isset( $outletInfo[ $userid ][ $fordate ] ) ) {
					$outlets = $outletInfo[ $userid ][ $fordate ];
				}
				if( isset( $pjpInfo[ $userid ][ $fordate ] ) ) {
					$pjps = $pjpInfo[ $userid ][ $fordate ];
				}
				if( isset( $claimInfo[ $userid ][ $fordate ] ) ) {
					$claims = $claimInfo[ $userid ][ $fordate ];
				}
				if( isset( $callInfo[ $userid ][ $fordate ] ) ) {
					$calls = $callInfo[ $userid ][ $fordate ];
				}
				//'orders','orderamount','payments','paymentamount','outlets','pjps','claims','calls'
				$insertValues[] = "( $userid, $companyid, $roleid, $report_login_times, $portal_login_times, $app_login_times, $status, '$fordate', '$month', '$week', $attendance_times, $activity_times, $isfree, $orders, $orderAmt, $payments, $paymentAmt, $outlets, $pjps, $claims, $calls, $oneview_report, $oneview_dashboard, $oldell_report, $oldell_dashboard )";
		}
		$sql = '';
		if( !empty( $insertValues ) ) {
				$insertQueries = array_chunk( $insertValues, 35000 );
				foreach( $insertQueries as $key => $insertQuery ) {
						$sql = "INSERT INTO `$tableName` ($columns) VALUES ";
						$sql .= implode( ",", $insertQuery );
						$sql .= ";";
						echo $sql."\n";
						$insert = $db->insert( $sql, FIRSTDB, $writeDB );
				}
		}
	}
}

// $query = "INSERT INTO `companyuserswithtransactions`(`id`, `app_login_times`, `portal_login_times`, `report_login_times`, `attendances`, `activities`, `calls`, `isfree`, `orders`, `orderamount`, `payments`, `paymentamount`, `outlets`, `pjps`, `claims`, `isactive`, `role_id`, `company_id`, `user_id`, `yearlymonth`, `yearlyweek`, `fordate`)
// SELECT `id`, `app_login_times`, `portal_login_times`, `report_login_times`, `attendances`, `activities`, `calls`, `isfree`, `orders`, `orderamount`, `payments`, `paymentamount`, `outlets`, `pjps`, `claims`, `isactive`, `role_id`, `company_id`, `user_id`, `yearlymonth`, `yearlyweek`, `fordate` FROM companyusers WHERE fordate >= '$fromDate' and fordate <= '$toDate'";
// $insert = $db->insert( $query, FIRSTDB, $writeDB );

function lastday( $month = '', $year = '' ) {
   if (empty($month)) {
          $month = date('m');
   }
   if (empty($year)) {
          $year = date('Y');
   }
   $result = strtotime("{$year}-{$month}-01");
   $result = strtotime('-1 second', strtotime('+1 month', $result));
   return date('Y-m-d', $result);
}

function firstDay($month = '', $year = '')
{
   if (empty($month)) {
          $month = date('m');
   }
   if (empty($year)) {
          $year = date('Y');
   }
   $result = strtotime("{$year}-{$month}-01");
   return date('Y-m-d', $result);
}
?>
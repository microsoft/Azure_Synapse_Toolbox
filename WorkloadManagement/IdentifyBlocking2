 /*
	==========================
	   Identify Blocking 2
	==========================
	NOTE: THIS QUERY IS NOT 100% ACCURATE, but is helpful in most cases. It attempts to link waiting queries to other queries that are blocking them.
    Sometimes if there are multiple queries blocking the waiting query, it cannot correctly identify the first query in the blocking chain.  
*/

WITH 
WaitingSidsList AS (
	SELECT 
		DateDiff(minute, waiting_waits.request_time, getdate()) as Wait_Time,
		waiting_waits.session_id AS        'Waiting_SID',
		waiting_waits.request_id AS        'Waiting_QID',
		blocking_waits.session_id AS    'Blocking_SID',
		blocking_waits.request_id AS    'Blocking_QID',
		waiting_waits.wait_id AS        'waiting_waitID',
		waiting_sessions.login_name AS    'Waiting_Login_Name',
		blocking_sessions.login_name AS    'Blocking_Login_Name',
		waiting_sessions.app_name AS    'Waiting_App_Name',
		blocking_sessions.app_name AS    'Blocking_App_name',
		waiting_PER.command AS            'Waiting_command',
		blocking_PER.command AS            'Blocking_command'
	FROM sys.dm_pdw_waits waiting_waits
	JOIN sys.dm_pdw_waits blocking_waits
		on waiting_waits.object_name = blocking_waits.object_name
		and waiting_waits.request_id != blocking_waits.request_id
	LEFT JOIN sys.dm_pdw_exec_sessions waiting_sessions
		ON waiting_waits.session_id = waiting_sessions.session_id
	LEFT JOIN sys.dm_pdw_exec_sessions blocking_sessions
		ON blocking_waits.session_id = blocking_sessions.session_id
	LEFT JOIN sys.dm_pdw_exec_requests waiting_PER
		ON waiting_PER.request_id = Waiting_waits.request_id
	LEFT JOIN sys.dm_pdw_exec_requests blocking_PER
		ON blocking_PER.request_id = blocking_waits.request_id
	WHERE waiting_waits.state = 'queued'
), 
MAX_WaitingSidsList AS (
	SELECT    Waiting_SID,
			MAX(waiting_waitID) as 'MAX_WaitID'
	FROM WaitingSidsList
	GROUP BY waiting_SID
) SELECT 
	 WaitingSidsList.Wait_Time AS 'Wait_Time_(M)',
	 WaitingSidsList.Waiting_SID,
	 WaitingSidsList.Waiting_QID,
	 WaitingSidsList.Blocking_SID,
	 WaitingSidsList.Blocking_QID,
	 WaitingSidsList.Waiting_Login_Name,
	 WaitingSidsList.Blocking_Login_Name,
	 WaitingSidsList.Waiting_App_Name,
	 WaitingSidsList.Blocking_App_name,
	 WaitingSidsList.Waiting_command,
	 WaitingSidsList.Blocking_command
FROM MAX_WaitingSidsList
JOIN WaitingSidsList
	ON MAX_WaitingSidsList.waiting_SID = WaitingSidsList.Waiting_SID
	AND MAX_WaitingSidsList.MAX_WaitID = WaitingSidsList.waiting_waitID
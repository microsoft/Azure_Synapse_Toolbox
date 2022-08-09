/***************************************************************************
	Synapse Toolkit v1.1, 06/13/22 
	
	The Synapse Toolkit is a set of stored procedures that help investigate
	current activity on your Synapse Dedicated SQL Pool. sp_status is the overall
	summary procedure that calls various other procedures to provide a picture
	of current activity. Use the detail_command columns to deep dive into a 
	particular session, query, or wait. 
	
	List of SPs currently included:
		sp_status
		sp_concurrency
		sp_requests
		sp_reqeusts_detail
		sp_sessions
		sp_sessions_detail
		sp_waits
		sp_waits_detail
		sp_datamovement
	
****************************************************************************/



/***************************************************************************
	Procedure name: sp_status
	Description: 
		Runs a few of the included SPs to give overall system utilization.
****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_status')
    EXEC ('CREATE PROC dbo.sp_status AS SELECT ''TEMPORARY''')
GO

ALTER PROC [dbo].[sp_status] AS

PRINT 'Synapse Toolkit v1.1, 06/13/22'

EXEC sp_concurrency;
EXEC sp_requests;
EXEC sp_datamovement
--EXEC sp_sessions

GO

/***************************************************************************
	Procedure name: sp_requests
	Description: 
		Collects running requests and suspended requests in two separate result windows.
		A running request provides a sp_requests_details query to see the plan for the 
		running query. A suspended request provides the sp_waits_detail query so you can 
		see why the query is in the suspended state. 

****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_requests')
    EXEC ('CREATE PROC dbo.sp_requests AS SELECT ''TEMPORARY''')
GO

ALTER PROC [dbo].[sp_requests] AS
SELECT 
	'Running Request' AS 'Running Requests'
	,s.session_id
	,r.request_id
	,s.login_name
	,r.submit_time
	,r.end_compile_time
	,r.total_elapsed_time
	,r.[label]
	,r.classifier_name
	,r.group_name
	,r.resource_allocation_percentage AS 'allocation_%'
	,r.command AS 'query_text'
	,r.result_cache_hit
	,'EXEC sp_requests_detail @Request_id=''' + r.request_id + '''' AS 'request_detail_command'
	,'EXEC sp_sessions_detail @session_id=''' + r.session_id + '''' AS 'session_detail_command'
FROM sys.dm_pdw_exec_requests r
JOIN sys.dm_pdw_exec_sessions s
on r.session_id = s.session_id
WHERE (r.group_name is not null OR r.result_cache_hit = 1)
AND r.[status] = 'Running'
OPTION(LABEL='SynapseToolkit')

SELECT 'Suspended Request' AS 'Suspended Requests'
	,s.session_id
	,r.request_id
	,s.login_name
	,r.submit_time
	,r.total_elapsed_time AS 'wait_time'
	,r.[label]
	,r.classifier_name
	,r.command AS 'query_text'
	,w.resource_waits AS 'concurrency_waits'
	,w.object_waits AS 'object_waits'
	,'EXEC sp_waits_detail @Request_id=''' + r.request_id + '''' AS 'waits_detail'
	,'EXEC sp_sessions_detail @session_id=''' + r.session_id + '''' AS 'session_detail_command'
FROM sys.dm_pdw_exec_requests r
JOIN sys.dm_pdw_exec_sessions s
on r.session_id = s.session_id
LEFT JOIN (
	SELECT 
	request_id
	,SUM(CASE WHEN object_type = 'SYSTEM' THEN 1 ELSE 0 END) AS resource_waits 
	,SUM(CASE WHEN object_type != 'SYSTEM' THEN 1 ELSE 0 END) AS object_waits
	FROM sys.dm_pdw_waits
	WHERE state != 'Granted'
	GROUP BY request_id
) w
ON r.request_id = w.request_id
WHERE r.[status] = 'Suspended'
OPTION(LABEL='SynapseToolkit')
GO

/***************************************************************************
	Procedure name: sp_requests_detail
	Description: 
		Provides the detailed query plan for the specified requestID. This shows
		a results at the distribution-level. Use Step_index to determine 
		which step you are looking at. 
****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_requests_detail')
    EXEC ('CREATE PROC dbo.sp_requests_detail AS SELECT ''TEMPORARY''')
GO

ALTER PROC [dbo].[sp_requests_detail] @request_id [varchar](20) AS
--Query Step Data
SELECT 
	'Query Plan' AS 'Query Plan'
	,rs.request_id
	,rs.step_index
	,rs.operation_type
	,rs.[status] AS 'step_status'
	,rs.estimated_rows AS 'step_estimated_rows'
	,rs.row_count AS 'step_actual_rows'
	,rs.total_elapsed_time AS 'step_elapsed_time'
	,dist.pdw_node_id
	,dist.distribution_id
	,dist.[type] AS 'distribution_step_type'
	,dist.[status] AS 'distribution_step_status'
	,dist.total_elapsed_time AS 'distribution_elapsed_time'
	,dist.bytes_per_sec
	,dist.bytes_processed
	,dist.row_count
	,dist.start_time
	,dist.end_time
	,dist.spid
	,rs.command
	,dist.error_id
 FROM 
	(--dms
	SELECT 
		request_id
		,step_index
		,pdw_node_id
		,distribution_id
		,type
		,status
		,start_time
		,end_time
		,total_elapsed_time
		,command
		,error_id
		,sql_spid AS spid
		,bytes_per_sec
		,bytes_processed
		,rows_processed AS row_count
		,command AS dist_text
	FROM sys.dm_pdw_dms_workers
	WHERE request_id = @request_id

	UNION ALL
	
	--sql
	SELECT 
		request_id
		,step_index
		,pdw_node_id
		,distribution_id
		,'SQL' AS type
		,[status]
		,start_time
		,end_time
		,total_elapsed_time
		,command
		,error_id
		,spid
		,-1 AS bytes_per_sec
		,-1 AS bytes_processed
		,row_count
		,command AS dist_text
	FROM sys.dm_pdw_sql_requests 
	WHERE request_id = @request_id
	AND command not like '%DISTRIBUTED_MOVE%'
	) dist
RIGHT JOIN sys.dm_pdw_request_steps rs
	ON rs.request_id = dist.request_id
	AND rs.step_index = dist.step_index
WHERE rs.request_id = @request_id
ORDER BY rs.step_index,dist.pdw_node_id,dist.distribution_id
OPTION(LABEL='SynapseToolkit')
GO

/***************************************************************************
	Procedure name: sp_waits
	Description: 
		Collects information on granted and queued object and resource (concurrency)
		waits. Provides statements for waits_detail queries to get more information on 
		what is blocking what.
****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_waits')
    EXEC ('CREATE PROC dbo.sp_waits AS SELECT ''TEMPORARY''')
GO

ALTER PROC [dbo].[sp_waits] AS
		--Granted Object Locks
		SELECT 'Granted Object Lock' AS 'Granted Object Locks'
				,w.session_id
				,w.request_id
				,r.[status] AS 'request_status'
				,w.[state] AS 'wait_state'
				,w.[type]
				,w.object_type
				,w.[object_name]
				,r.importance
				,r.classifier_name
				,r.group_name
				,w.priority
				,w.request_time
				,w.acquire_time
				,r.total_elapsed_time AS 'request_elapsed_time'
				,r.[label]
				,r.command AS 'query_text'
				--,'EXEC sp_waits_detail @Request_id=''' + w.request_id + '''' AS 'detail_command'
				FROM sys.dm_pdw_waits w
				JOIN sys.dm_pdw_exec_requests r 
				ON w.request_id = r.request_id
				WHERE w.object_type != 'SYSTEM'
				AND w.[state]='Granted'
				AND r.[status] != 'Completed'
				AND w.session_id != SESSION_ID()
				ORDER BY r.[status],r.start_time,r.submit_time,w.priority asc
				OPTION(LABEL='SynapseToolkit')

		--Queued Locks
				SELECT 'Queued Object Lock' AS 'Queued Object Locks'
				,w.session_id
				,w.request_id
				,r.[status] AS 'request_status'
				,w.[state] AS 'wait_state'
				,w.[type]
				,w.object_type
				,w.[object_name]
				,r.importance
				,r.classifier_name
				,r.group_name
				,w.priority
				,w.request_time
				,w.acquire_time
				,r.total_elapsed_time AS 'request_elapsed_time'
				,r.[label]
				,r.command AS 'query_text'
				,'EXEC sp_waits_detail @Request_id=''' + w.request_id + '''' AS 'detail_command'
				FROM sys.dm_pdw_waits w
				JOIN sys.dm_pdw_exec_requests r 
				ON w.request_id = r.request_id
				WHERE w.object_type != 'SYSTEM'
				AND w.[state]!='Granted'
				AND r.[status] != 'Completed'
				ORDER BY r.[status],r.start_time,r.submit_time,w.priority asc
				OPTION(LABEL='SynapseToolkit')

				--Granted concurrency waits
				SELECT 'Granted Concurrency Wait' AS 'Granted Concurrency Waits'
			,w.session_id
			,w.request_id
			,r.[status] AS 'request_status'
			,w.[state] AS 'wait_state'
			,r.resource_allocation_percentage
			,r.importance
			,r.classifier_name
			,r.group_name
			,w.priority
			,w.request_time
			,w.acquire_time
			,r.total_elapsed_time AS 'request_elapsed_time'
			,r.[label]
			,r.command AS 'query_text'
		FROM sys.dm_pdw_waits w
		JOIN sys.dm_pdw_exec_requests r
		on w.request_id = r.request_id
		WHERE object_type = 'SYSTEM'
		AND w.[state]='Granted'
		AND w.[type] NOT IN ('ConcurrencyResourceType','LocalQueriesConcurrencyResourceType')
		ORDER BY w.session_id,w.request_id,w.wait_id
		OPTION(LABEL='SynapseToolkit')

		--Queued concurrency waits
		SELECT 'Queued Concurrency Wait' AS 'Queued Concurrency Waits'
			,w.session_id
			,w.request_id
			,r.[status] AS 'request_status'
			,w.[state] AS 'wait_state'
			,r.resource_allocation_percentage
			,r.importance
			,r.classifier_name
			,r.group_name
			,w.priority
			,w.request_time
			,w.acquire_time
			,r.total_elapsed_time AS 'request_elapsed_time'
			,r.[label]
			,r.command AS 'query_text'
		FROM sys.dm_pdw_waits w
		JOIN sys.dm_pdw_exec_requests r
		on w.request_id = r.request_id
		WHERE object_type = 'SYSTEM'
		AND w.[state]!='Granted'
		AND w.[type] NOT IN ('ConcurrencyResourceType','LocalQueriesConcurrencyResourceType')
		ORDER BY w.session_id,w.request_id,w.wait_id
		OPTION(LABEL='SynapseToolkit')
	
GO

/***************************************************************************
	Procedure name: sp_waits_detail
	Description: 
	When providing a suspended requestID:
		This sp will return all queries that have object locks on the same objects
		the provided query is queued on
	This query returns a message if a query with no waiting object locks is provided

****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_waits_detail')
    EXEC ('CREATE PROC dbo.sp_waits_detail AS SELECT ''TEMPORARY''')
GO

ALTER PROC [dbo].[sp_waits_detail] @request_id [varchar](20) AS

--If the provided statement is suspended, show what's blocking it

IF (SELECT [status] FROM sys.dm_pdw_exec_requests WHERE request_id = @request_id) = 'Suspended'
	BEGIN
		IF (SELECT TOP 1 [object_type] FROM sys.dm_pdw_waits WHERE request_id = @request_id AND STATE != 'GRANTED' ) != 'SYSTEM'
		BEGIN
			--Queued Object Locks for provided query
			SELECT 'Blocked Object Lock' AS 'Blocked Object Locks'
			,session_id
			,request_id
			,wait_id
			,[state]
			,[type]
			,object_type
			,[object_name]
			,priority
			,request_time
			,acquire_time
			FROM sys.dm_pdw_waits
			WHERE object_type != 'SYSTEM'
			AND [state]!='Granted'
			AND request_id = @request_id
			ORDER BY session_id,wait_id
			OPTION(LABEL='SynapseToolkit')
		
			--Granted Locks on the same objects as in query
			SELECT 'Possible Blocker' AS 'Possible Blockers'
			,w2.session_id
			,w2.request_id
			,w2.wait_id
			,w2.[state]
			,w2.[type]
			,w2.object_type
			,w2.[object_name]
			,w2.priority
			,w2.request_time
			,w2.acquire_time 
			,'EXEC sp_requests_detail @Request_id=''' + w2.request_id + '''' AS 'request_detail_command'
			,'EXEC sp_sessions_detail @session_id=''' + w2.session_id + '''' AS 'session_detail_command'
			FROM sys.dm_pdw_waits w1
			JOIN sys.dm_pdw_waits w2
			ON w1.[object_name] = w2.[object_name]
			WHERE w1.request_id = @request_id
			AND w2.[state] = 'Granted'
			ORDER BY w2.session_id,w2.wait_id
			OPTION(LABEL='SynapseToolkit')
		END

	END
	ELSE
		BEGIN
			SELECT 'No queued object Locks found for ' + @request_id AS 'Message'
		END

GO



/***************************************************************************
	Procedure name: sp_concurrency
	Description: 
		Shows general information about how many queries are running/suspended
		and how many queued object locks or resource (concurrency) locks. Also 
		shows the currentl percentage of resources allocated to running queries
		by workload group assignment
****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_concurrency')
    EXEC ('CREATE PROC dbo.sp_concurrency AS SELECT ''TEMPORARY''')
GO

ALTER PROC [dbo].[sp_concurrency] AS 

SELECT
	sum(case when r.status = 'Running' then r.resource_allocation_percentage else 0 end) as 'resource_allocated_percentage'
	--,sum(case when s.status = 'Active' then 1 else 0 end) as 'active_sessions'
	--sum(case when s.status = 'Idle' then 1 else 0 end) as 'idle_sessions'
	,(SELECT count(1) FROM sys.dm_pdw_exec_sessions where status = 'Active') AS 'active_sessions'
	,(SELECT count(1) FROM sys.dm_pdw_exec_sessions where status = 'Idle') AS 'idle_sessions'
	,sum(case when r.status = 'Running' AND (r.group_name is not null OR r.result_cache_hit = 1) then 1 else 0 end) as running_queries
	,sum(case when r.status = 'suspended' then 1 else 0 end) as queued_queries
	,sum(case when w.queued_resource_waits > 0 then 1 else 0 end) AS concurrency_waits
	,sum(case when w.queued_object_locks > 0 then 1 else 0 end) AS object_waits
FROM 
sys.dm_pdw_exec_requests r
JOIN sys.dm_pdw_exec_sessions s
ON r.session_id = s.session_id
LEFT JOIN (
	SELECT 
		request_id
		,count(request_id) AS queued_locks
		,sum(case when object_type = 'system' then 1 else 0 end) as queued_resource_waits
		,sum(case when object_type != 'system' then 1 else 0 end) as queued_object_locks
	FROM sys.dm_pdw_waits
	WHERE state != 'Granted'
	GROUP BY request_id
	) w
ON w.request_id = r.request_id
OPTION(LABEL='SynapseToolkit')



GO
/***************************************************************************
	Procedure name: sp_datamovement
	Description: 
		Shows all data movement currently happening in order from largest to 
		smallest. The items at the top of this list are likely the most resource-
		intensive queries currently running. 
****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_datamovement')
    EXEC ('CREATE PROC dbo.sp_datamovement AS SELECT ''TEMPORARY''')
GO

ALTER PROC sp_datamovement AS

WITH step_data AS 
(
	SELECT 
		SUM(rows_processed) AS Step_Rows_Processed
		, SUM(Bytes_processed) AS Step_Bytes_Processed
		, max(total_elapsed_time) AS Step_elapsed_time
		, request_id
		, step_index
		, status 
		--, type
	FROM sys.dm_pdw_dms_workers 
	WHERE status != 'StepComplete'
	Group by 
		  request_id
		, step_index
		, status
		--, type
) 
SELECT 
	'Data Movement' AS 'Data Movements'
	,s.login_name
	,step_data.request_id
	, per.session_id
	, rs.operation_type
	, (step_data.Step_elapsed_time/1000/60) AS 'step_elapsed_time_(m)'
	, step_data.Step_rows_processed
	, step_data.step_bytes_processed
	, (step_data.Step_Bytes_Processed/1024/1024/1024) AS Step_GB_Processed
	, step_data.step_index
	--, step_data.type
	, step_data.status as Step_status
	--, per.status AS QID_Status
	, per.total_elapsed_time/1000/60 as 'QID_elapsed_time(m)'
	, per.command AS 'QID_Command'
	, per.resource_class
	, per.importance
	,'EXEC sp_requests_detail @Request_id=''' + per.request_id + '''' AS 'request_detail_command'
FROM step_data
LEFT JOIN sys.dm_pdw_exec_requests per
ON step_data.request_id = per.request_id
JOIN sys.dm_pdw_exec_sessions s
ON per.session_id = s.session_id
JOIN sys.dm_pdw_request_steps rs
ON step_data.request_id = rs.request_id
AND step_data.step_index = rs.step_index
WHERE per.status = 'Running'
ORDER BY step_data.Step_rows_processed DESC
OPTION(LABEL='SynapseToolkit')

GO
/***************************************************************************
	Procedure name: sp_sessions
	Description: status of all open sessions

****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_sessions')
    EXEC ('CREATE PROC dbo.sp_sessions AS SELECT ''TEMPORARY''')

GO

ALTER PROC sp_sessions AS

SELECT 
	'Active Session' AS 'Active Sessions'
	,s.session_id
	,s.request_id
	,s.login_name
	,s.login_time
	,s.query_count
	,s.client_id
	,s.[app_name]
	,'EXEC sp_sessions_detail @session_id=''' + s.session_id + '''' AS 'detail_command'
FROM sys.dm_pdw_exec_sessions s
WHERE s.[status] = 'active'
order by login_time asc
OPTION(LABEL='SynapseToolkit')

SELECT 
	'Idle Session' AS 'Idle Sessions'
	,s.session_id
	,s.request_id
	,s.login_name
	,s.login_time
	,s.query_count
	,s.client_id
	,s.[app_name]
	,'EXEC sp_sessions_detail @session_id=''' + s.session_id + '''' AS 'detail_command'
FROM sys.dm_pdw_exec_sessions s
WHERE s.[status] = 'idle'
order by login_time asc
OPTION(LABEL='SynapseToolkit')

GO

/***************************************************************************
	Procedure name: sp_sessions_detail
	Description: 

****************************************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_sessions_detail')
    EXEC ('CREATE PROC dbo.sp_sessions_detail AS SELECT ''TEMPORARY''')

GO

ALTER PROC sp_sessions_detail @session_id [varchar](20) AS

SELECT 
	Session_id
	,request_id
	,[status]
	,submit_time
	,end_compile_time
	,start_time
	,end_time
	,total_elapsed_time/1000 AS 'total_elapsed_time_s'
	,[label]
	,error_id
	,command
	,command2
	,classifier_name
	,group_name
	,importance
	,resource_allocation_percentage
	,result_cache_hit
	,'EXEC sp_requests_detail @Request_id=''' + request_id + '''' AS 'detail_command'
FROM sys.dm_pdw_exec_requests
WHERE session_id = @session_id
ORDER BY submit_time ASC
OPTION(LABEL='SynapseToolkit')

/***************************************************************************
	Procedure name: 
	Description: 

****************************************************************************/
/*IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = '')
    EXEC ('CREATE PROC dbo. AS SELECT ''TEMPORARY''')
GO
*/
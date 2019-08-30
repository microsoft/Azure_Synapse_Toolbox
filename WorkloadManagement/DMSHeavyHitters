/*
	==========================
	   DMS Heavy Hitters
	==========================
	The following query returns queries that are currently processing rows in DMS sorted from largest to smallest. 
    Queries that are processing very large amounts of rows or volume of data could be spilling to tempdb and impacting other queries. 
    When troubleshooting a "general slowness" issue, this query can help you find the query steps that are most likley to be impacting 
    other resources. 
*/
WITH step_data AS 
(
	SELECT 
		SUM(rows_processed) AS Step_Rows_Processed
		, SUM(Bytes_processed) AS Step_Bytes_Processed
		, request_id
		, step_index
		, status 
		, type
	FROM sys.dm_pdw_dms_workers 
	WHERE status != 'StepComplete'
	Group by 
		  request_id
		, step_index
		, status
		, type
) 
SELECT 
	 step_data.request_id
	, per.session_id
	, step_data.Step_rows_processed
	, step_data.step_bytes_processed
	, (step_data.Step_Bytes_Processed/1024/1024/1024) AS Step_GB_Processed
	, step_data.step_index
	, step_data.type
	, step_data.status as Step_status
	, per.status AS QID_Status
	, per.total_elapsed_time/1000/60 as 'QID_Elapsed_Time (min)'
	, per.command AS 'QID_Command'
	, per.resource_class
	, per.importance
FROM step_data
LEFT JOIN sys.dm_pdw_exec_requests per
ON step_data.request_id = per.request_id
WHERE per.status = 'Running'
ORDER BY step_data.Step_rows_processed DESC
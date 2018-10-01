/*
	=======================
	   Queued Query Time
	=======================
	The following query looks for queries that had the longest time between submit_time and 
	start_time. These queries were blocked by resources being locked or waiting for a concurrentcy slot. 
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/analyze-your-workload
*/
SELECT  r.[request_id]                           AS Request_ID
,       r.[status]                               AS Request_Status
,       r.[submit_time]                          AS Request_SubmitTime
,       r.[start_time]                           AS Request_StartTime
,       DATEDIFF(ms,[submit_time],[start_time])  AS Request_InitiateDuration_ms
,       r.resource_class                         AS Request_resource_class
FROM    sys.dm_pdw_exec_requests r
ORDER BY Request_InitiateDuration_ms desc
;

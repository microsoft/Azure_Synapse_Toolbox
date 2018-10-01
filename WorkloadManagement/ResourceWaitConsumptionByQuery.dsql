/*
	========================================
	   Resource Wait Consumption by Query
	========================================
	The following query Will show resource waits consumed by a given query. 
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/analyze-your-workload
*/
SELECT  [session_id]
,       [type]
,       [object_type]
,       [object_name]
,       [request_id]
,       [request_time]
,       [acquire_time]
,       DATEDIFF(ms,[request_time],[acquire_time])  AS acquire_duration_ms
,       [concurrency_slots_used]                    AS concurrency_slots_reserved
,       [resource_class]
,       [wait_id]                                   AS queue_position
FROM    sys.dm_pdw_resource_waits
WHERE    [session_id] <> SESSION_ID()
;
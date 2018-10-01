/*
	===============================
	   Granted Concurrency Slots
	===============================
	The following query will show how many conccurency slots are currently granted
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/analyze-your-workload
*/
SELECT  SUM([concurrency_slots_used]) as total_granted_slots 
FROM    sys.[dm_pdw_resource_waits] 
WHERE   [state]           = 'Granted' 
AND     [resource_class] is not null
AND     [session_id]     <> session_id()
;
/*
	=================================
	   Used Concurrency Slots Info
	=================================
	The following query will show details of current granted and waiting concurrency slots including:
		How many concurrency slots are used
		What resource class the query is running in
		The query text
*/
SELECT prw.Session_id, 
	prw.request_id, 
	prw.request_time, 
	prw.acquire_time, 
	prw.state, 
	prw.priority, 
	prw.concurrency_slots_used,
	prw.resource_class,
	per.command AS 'Query_text'
FROM sys.dm_pdw_resource_waits prw
JOIN sys.dm_pdw_exec_requests per
ON prw.request_id = per.request_id
WHERE type = 'UserConcurrencyResourceType'
ORDER BY state,concurrency_slots_used DESC
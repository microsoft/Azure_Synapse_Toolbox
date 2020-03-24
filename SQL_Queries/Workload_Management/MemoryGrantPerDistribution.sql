/*
	===================================
	   Memory Grant Per Distribution
	===================================
	This query will return information on the memory grants per distribution.I n reality, 
	your memory grant is less than the results of the following query. However, this query 
	provides a level of guidance that you can use when sizing your partitions for data
	management operations. Maximum memory per distribution is govered by resource classes.
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-tables-partition
*/
SELECT  rp.[name]                       		AS [pool_name]
,       rp.[max_memory_kb]						AS [max_memory_kb]
,       rp.[max_memory_kb]/1024         		AS [max_memory_mb]
,       rp.[max_memory_kb]/1048576      		AS [mex_memory_gb]
,       rp.[max_memory_percent]         		AS [max_memory_percent]
,       wg.[name]                       		AS [group_name]
,       wg.[importance]                			AS [group_importance]
,       wg.[request_max_memory_grant_percent]   AS [request_max_memory_grant_percent]
FROM    sys.dm_pdw_nodes_resource_governor_workload_groups    wg
JOIN    sys.dm_pdw_nodes_resource_governor_resource_pools    rp ON wg.[pool_id] = rp.[pool_id]
WHERE   wg.[name] like 'SloDWGroup%'
AND     rp.[name]    = 'SloDWPool'
;
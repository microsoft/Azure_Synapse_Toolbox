/*	
	================================
	   Replicated Tables Modified
	   but not rebuilt
	=================================

	The following query will list replicated tables that have been modified, 
	but not rebuilt. THis will cause a rebuild at execution time next time the 
	table is touched and will affect performance.
	You can manually trigger a rebuild by:
		SELECT TOP 1 * FROM [ReplicatedTable]

	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/design-guidance-for-replicated-tables
*/
SELECT [ReplicatedTable] = t.[name]
  FROM sys.tables t  
  JOIN sys.pdw_replicated_table_cache_state c  
    ON c.object_id = t.object_id 
  JOIN sys.pdw_table_distribution_properties p 
    ON p.object_id = t.object_id 
  WHERE c.[state] = 'NotReady'
    AND p.[distribution_policy_desc] = 'REPLICATE'
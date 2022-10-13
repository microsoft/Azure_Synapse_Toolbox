/*
	=============================
	   Row count per partition
	=============================
	This query will use sys.dm_pdw_nodes_db_partition_stats to return the row count in each partition
	for the specified table. Using sys.dm_pdw_nodes_db_partition_stats is much more 
	accurate than just using sys.partition_stats.
	
*/
SELECT 
	pnp.partition_number
	,s.[name]
	,t.[name]
	,sum(nps.[row_count])
	,sum(nps.[used_page_count]*8.0/1024) as usedSpaceMB
 FROM
   sys.tables t
INNER JOIN sys.indexes i
    ON  t.[object_id] = i.[object_id]
    AND i.[index_id] <= 1 /* HEAP = 0, CLUSTERED or CLUSTERED_COLUMNSTORE =1 */
INNER JOIN sys.pdw_table_mappings tm
    ON t.[object_id] = tm.[object_id]
INNER JOIN sys.pdw_nodes_tables nt
    ON tm.[physical_name] = nt.[name]
INNER JOIN sys.pdw_nodes_partitions pnp 
    ON nt.[object_id]=pnp.[object_id] 
    AND nt.[pdw_node_id]=pnp.[pdw_node_id] 
    AND nt.[distribution_id] = pnp.[distribution_id]
INNER JOIN sys.dm_pdw_nodes_db_partition_stats nps
    ON nt.[object_id] = nps.[object_id]
    AND nt.[pdw_node_id] = nps.[pdw_node_id]
    AND nt.[distribution_id] = nps.[distribution_id]
    AND pnp.[partition_id]=nps.[partition_id]
JOIN sys.schemas s
	ON s.[schema_id] = t.[schema_id]
WHERE s.name = 'dbo' --comment out for all schemas 
AND t.name='FactInternetSales_partitioned' --comment out for all tables
GROUP BY pnp.partition_number,s.[name],t.[name]
ORDER BY pnp.partition_number ASC;
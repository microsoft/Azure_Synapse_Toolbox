/*
	============================================
	   Rebuild Columnstore Index By partiiton
	============================================
	This query will loop through all partitions in a table and rebuild
	the columnstore index per partition. Perfoming rebuilds this way require
	a smaller memory grant 
	
	SET Schema, dbo, and number of partitions to alter before running

*/
--Set these 3 variables
DECLARE @schemaName VARCHAR(50) = 'dbo' 
DECLARE @tableName VARCHAR(100) = 'FactInternetSales_partitioned'
DECLARE @numPartitionsToAlter INT = 2 --1 for only max partition with data, 2 for last 2, etc.

DECLARE @counter INT 
DECLARE @maxPartitionWithData INT 

SET @maxPartitionWithData=(
			SELECT 
				max(pnp.partition_number) AS 'Max_Parititon_With_Data'
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
			WHERE s.name = @schemaName 
			AND t.name=@tableName
			AND nps.[row_count] > 0
			GROUP BY s.[name],t.[name]
			)
SET @counter=@maxPartitionWithData - @numPartitionsToAlter + 1

WHILE ( @counter <= @maxPartitionWithData)
BEGIN
	DECLARE @s NVARCHAR(4000) = N''

	--SET @s = ('ALTER INDEX ALL ON ' + @schemaName + '.' + @tableName + ' REBUILD PARTITION = ' + CAST(@counter AS varchar(10))) --rebuild command (offline operation)
	SET @s = ('ALTER INDEX ALL ON ' + @schemaName + '.' + @tableName + ' REORGANIZE PARTITION = ' + CAST(@counter AS varchar(10)) + ' WITH (COMPRESS_ALL_ROW_GROUPS = ON)') --REORGANIZE command (online operation)
	PRINT @s

	EXEC sp_executesql @s

    SET @counter  = @counter  + 1
END
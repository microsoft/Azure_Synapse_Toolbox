/*
	=================================================
	   Clustered Columnstore Index Health by Table
	=================================================

	This query will return the health of the columnstore index on each table. 

	Collection Date:	Date this collection was ran
	Database Name		 
	Table Name
	Distribution Type:	Hash (distributed), Replicated, Round Robin. 
	Open Row Group: 
*/

SELECT               
	SYSDATETIME()													as 'Collection_Date',
    DB_Name()														as 'Database_Name',
    t.name															as 'Table_Name',
	tdp.distribution_policy_desc									as 'Distribution_type',
    SUM(CASE WHEN rg.State = 1 THEN 1 else 0 end)					as 'OPEN_Row_Groups',
    SUM(CASE WHEN rg.State = 1 THEN rg.Total_rows else 0 end)		as 'OPEN_rows',
    MIN(CASE WHEN rg.State = 1 THEN rg.Total_rows else NULL end)	as 'MIN OPEN Row Group Rows',
    MAX(CASE WHEN rg.State = 1 THEN rg.Total_rows else NULL end)	as 'MAX OPEN_Row Group Rows',
    AVG(CASE WHEN rg.State = 1 THEN rg.Total_rows else NULL end)	as 'AVG OPEN_Row Group Rows',
 
    SUM(CASE WHEN rg.State = 3 THEN 1 else 0 end)					as 'COMPRESSED_Row_Groups',
    SUM(CASE WHEN rg.State = 3 THEN rg.Total_rows else 0 end)		as 'COMPRESSED_Rows',
	SUM(CASE WHEN rg.State = 3 THEN rg.deleted_rows else 0 end)		as 'Deleted_COMPRESSED_Rows',
	MIN(CASE WHEN rg.State = 3 THEN rg.Total_rows else NULL end)	as 'MIN COMPRESSED Row Group Rows',
    MAX(CASE WHEN rg.State = 3 THEN rg.Total_rows else NULL end)	as 'MAX COMPRESSED Row Group Rows',
    AVG(CASE WHEN rg.State = 3 THEN rg.Total_rows else NULL end)	as 'AVG_COMPRESSED_Rows',
 
    SUM(CASE WHEN rg.State = 2 THEN 1 else 0 end)					as 'CLOSED_Row_Groups',
    SUM(CASE WHEN rg.State = 2 THEN rg.Total_rows else 0 end)		as 'CLOSED_Rows',
	MIN(CASE WHEN rg.State = 2 THEN rg.Total_rows else NULL end)	as 'MIN CLOSED Row Group Rows',
    MAX(CASE WHEN rg.State = 2 THEN rg.Total_rows else NULL end)	as 'MAX CLOSED Row Group Rows',
    AVG(CASE WHEN rg.State = 2 THEN rg.Total_rows else NULL end)	as 'AVG CLOSED Row Group Rows'
FROM sys.pdw_nodes_column_store_row_groups rg
INNER JOIN sys.pdw_nodes_tables pt
	ON rg.object_id = pt.object_id
	AND rg.pdw_node_id = pt.pdw_node_id
INNER JOIN sys.pdw_table_mappings mp
	ON pt.name = mp.physical_name
INNER JOIN sys.tables t
	ON     mp.object_id = t.object_id
INNER JOIN sys.pdw_table_distribution_properties as tdp
	ON tdp.object_id = t.object_id
GROUP BY t.name,tdp.distribution_policy_desc
 

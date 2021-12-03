SELECT 
    s.name AS SchemaName
    , t.name AS TableName
    , MAX(i.last_user_seek) as Last_seek
    , MAX(i.last_user_scan) as last_scan
    , MAX(i.last_user_lookup) as last_lookup
    , MAX(i.last_user_update) as last_update 
FROM sys.schemas s
INNER JOIN sys.tables t
    ON s.schema_id = t.schema_id
INNER JOIN sys.pdw_permanent_table_mappings ptm
    ON t.object_id = ptm.object_id
INNER JOIN sys.pdw_nodes_tables nt
    ON ptm.physical_name = nt.name
INNER JOIN sys.dm_pdw_nodes_db_index_usage_stats i
    ON i.object_id = nt.Object_id
INNER JOIN sys.databases d
    ON i.database_id = d.database_id
WHERE d.database_id <> 1
    --AND s.name = '<schema>'
GROUP BY s.name, t.name
ORDER BY last_scan DESC
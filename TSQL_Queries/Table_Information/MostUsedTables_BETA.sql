--This query joins the index usage stats from all nodes to determine which tables are the most used. 
SELECT 
	s.name
	, t.name
	, MAX(pnt.create_date) AS create_date
	, MAX(pnt.modify_date) AS modify_date
	, MAX(IUS.user_seeks) AS user_seeks
	, MAX(IUS.user_scans) AS user_scans
	, MAX(IUS.user_lookups) AS user_lookups
	, MAX(IUS.user_updates) AS user_updates
	, MAX(IUS.last_user_seek) AS last_user_seek
	, MAX(IUS.last_user_scan) AS last_user_scan
	, MAX(IUS.last_user_lookup) AS last_user_lookup
	, MAX(IUS.last_user_update) AS last_user_update
	, SUM(IUS.user_seeks + IUS.user_scans + IUS.user_lookups + IUS.user_updates) AS total_touches
FROM sys.pdw_nodes_tables pnt 
LEFT JOIN sys.dm_pdw_nodes_db_index_usage_stats IUS
	ON IUS.object_id = pnt.object_id
JOIN sys.pdw_table_mappings ptm
	ON ptm.physical_name = pnt.name
JOIN sys.tables t
	ON t.object_id = ptm.object_id
JOIN sys.schemas s
	ON s.schema_id = t.schema_id
GROUP BY t.object_id, s.name,t.name
ORDER BY total_touches DESC


--Tempdb usage per node
SELECT 
	'TempDB per node' AS 'TempDB per node'
	,pdw.pdw_node_id
	,n.type
	,sum(pdw.bytes_processed) as 'bytes_written'
	,CAST(sum(pdw.bytes_processed)/1024.0/1024.0/1024.0 AS Decimal(10,1)) AS 'GB_written'
	,'1995' AS 'Total_tempDB_size_GB'
	,CAST(((sum(pdw.bytes_processed)/1024.0/1024.0/1024.0)/1995.0)*100 AS Decimal(10,1)) AS 'percent_used'
	,sum(pdw.rows_processed) as 'rows_written'
FROM sys.dm_pdw_nodes n
LEFT JOIN Sys.dm_pdw_dms_workers pdw
	ON n.pdw_node_id = pdw.pdw_node_id
LEFT JOIN sys.dm_pdw_exec_requests req
	ON pdw.request_id = req.request_id
WHERE pdw.type = 'Writer'
AND req.status = 'running'
GROUP BY n.type,pdw.pdw_node_id
ORDER BY bytes_written desc

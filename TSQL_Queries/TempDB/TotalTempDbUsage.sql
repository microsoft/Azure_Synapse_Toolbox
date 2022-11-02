--Total TempDB Usage
SELECT
	'Total TempDB usage' AS 'Total TempDB usage'
	,sum(pdw.rows_processed) as 'rows_written'
	,sum(pdw.bytes_processed) as 'bytes_written'
	,CAST(sum(pdw.bytes_processed)/1024.0/1024.0/1024.0 AS Decimal(10,1)) AS 'GB_written'
	,total_tempdb.total_tempdb_gb as 'Total_tempDB_size_GB'
	,CAST(((sum(pdw.bytes_processed)/1024.0/1024.0/1024.0)/total_tempdb.total_tempdb_gb)*100.0 AS Decimal(10,1)) AS 'approx_percent_used'
FROM Sys.dm_pdw_dms_workers pdw
JOIN sys.dm_pdw_exec_requests req
	ON pdw.request_id = req.request_id
JOIN (SELECT (count(1) * 1995) AS total_tempdb_gb FROM sys.dm_pdw_nodes WHERE type='COMPUTE') AS total_tempdb
	ON 1=1
WHERE pdw.type = 'Writer'
AND req.status = 'running'
GROUP BY total_tempdb.total_tempdb_gb
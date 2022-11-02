--Tempdb usage per query
SELECT 
	'TempDB per query' AS 'TempDB per query'
	,req.request_id
	,sum(pdw.bytes_processed) as 'bytes_written'
	,CAST(sum(pdw.bytes_processed)/1024.0/1024.0/1024.0 AS Decimal(10,1)) AS 'GB_written'
	,sum(pdw.rows_processed) as 'rows_written'
	,'EXEC sp_requests_detail @request_id=''' + req.request_id + '''' AS 'request_detail_command'
from	Sys.dm_pdw_dms_workers pdw
JOIN sys.dm_pdw_exec_requests req
ON pdw.request_id = req.request_id
WHERE pdw.type = 'Writer'
AND req.status = 'running'
GROUP BY req.request_id
ORDER BY bytes_written desc
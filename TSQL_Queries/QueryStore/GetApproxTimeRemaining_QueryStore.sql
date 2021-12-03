--Calculate approximate time remaining for running queries based on hits on teh query text in query store. 
SELECT
req.session_id,
req.request_id,
req.total_elapsed_time/1000/60 As Elapsed_minutes,
ROUND(avg(abs([stats].avg_duration))/1000/1000/60,1) as 'AVG_Duration (min)',
min(abs([stats].min_duration))/1000/1000/60 AS 'MIN_Duration (min)',
MAX(abs([stats].max_duration))/1000/1000/60 AS 'MAX_duration (min)',
ROUND((avg(abs([stats].avg_duration))/1000 - req.total_elapsed_time)/1000/60,1) AS avg_estimated_mins_remaining,
(min(abs([stats].min_duration))/1000 - req.total_elapsed_time)/1000/60 AS min_estimated_mins_remaining,
(MAX(abs([stats].max_duration))/1000 - req.total_elapsed_time)/1000/60 AS max_estimated_mins_remaining,
req.command
FROM sys.dm_pdw_exec_requests req
LEFT JOIN sys.query_store_query_text [text] 
ON LEFT(req.command,4000) = LEFT([text].query_sql_text,4000)
LEFT JOIN sys.query_store_query query
ON query.query_text_id = [text].query_text_id
LEFT JOIN sys.query_store_plan [plan]
ON query.query_id = [plan].query_id
LEFT JOIN sys.query_store_runtime_stats [stats]
ON [stats].plan_id = [plan].plan_id
WHERE req.status = 'Running'
AND req.resource_allocation_percentage IS NOT NULL
AND [stats].Execution_type = 0
GROUP BY req.command,req.request_id,req.total_elapsed_time,req.session_id
order by req.total_elapsed_time desc

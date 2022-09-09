--Recently ran queries still in exec_requests
SELECT r.[session_id]
	,r.[request_id]
	,r.[status]
	,s.[login_name]
	,r.[command]
	,r.[submit_time]
	,r.[end_time]
	--,r.[end_compile_time]
	,datediff(ms,r.[submit_time], r.[end_compile_time]) AS [compile_time_ms]
	,datediff(ms,r.[end_compile_time],r.[start_time]) AS [wait_time_ms]
	,datediff(ms,r.[start_time], r.[end_time]) AS [execution_time_ms]
	,r.[total_elapsed_time] AS [total_time_ms]
	,sum(CASE WHEN row_count=('-1') THEN 0 ELSE row_count END) AS [Total_Rows_Processed]
	,r.[label]
	,r.[resource_allocation_percentage]
	,r.[importance]
	,r.[group_name]
	,r.[classifier_name]
	,r.[result_cache_hit]
	,s.[app_name]
	FROM sys.dm_pdw_exec_requests r
LEFT JOIN sys.dm_pdw_exec_sessions s
ON r.[session_id] = s.[session_id]
LEFT JOIN sys.dm_pdw_request_steps steps
ON r.[request_id] = steps.[request_id]
--WHERE [group_name] is not null
GROUP BY r.[request_id],r.[session_id],r.[status],r.[submit_time],r.[end_compile_time],r.[start_time],r.[end_time],r.[total_elapsed_time],r.[label],r.[command],r.[importance],r.[group_name],r.[classifier_name],r.[resource_allocation_percentage],r.[result_cache_hit],s.[login_name],s.[app_name] 
ORDER BY r.[submit_time] desc

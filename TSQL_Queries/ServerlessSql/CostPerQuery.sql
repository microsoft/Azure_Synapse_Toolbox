SELECT 

       ERH.status as [status],

       ERH.login_name as [login_name],

       ERH.start_time as [start_time],

       ERH.end_time as [end_time],

       ERH.total_elapsed_time_ms as [duration_ms],



       /* Data processed =  data scanned + data moved + data written */

       ERH.data_processed_mb as [data_processed_MB],



       /* Cost management for serverless SQL pool

       The amount of data processed is rounded up to the nearest MB per query. 

       Each query has a minimum of 10 MB of data processed. */

       CASE WHEN ERH.data_processed_mb < 10 THEN 10 ELSE ERH.data_processed_mb END as [data_pricing_MB],

       

       cast(ERH.total_elapsed_time_ms/1000.0 as decimal(12,2)) as [duration_sec],

       /*$5 per 1TB scan, minimum 10M */

       cast((CASE WHEN ERH.data_processed_mb < 10 THEN 10 ELSE ERH.data_processed_mb END)*5/100000.0 as decimal(19,7))  as cost_in_$,

       ERH.command as [statement],

       ERH.query_text as [command]       

FROM sys.dm_exec_requests_history ERH

ORDER BY ERH.start_time desc

--order by cast((CASE WHEN ERH.data_processed_mb < 10 THEN 10 ELSE ERH.data_processed_mb END)*5/100000.0 as decimal(19,7)) desc
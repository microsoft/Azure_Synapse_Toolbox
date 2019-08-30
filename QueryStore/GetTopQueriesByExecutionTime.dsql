/*
	====================================
	   Top Queries By Execution Time
	====================================
	The following query will find the top queries by execution time
*/
SELECT
       q.query_id               [query_id]
       , t.query_sql_text       [command]
       , rs.avg_duration        [avg_duration]
       , rs.min_duration        [min_duration]
       , rs.max_duration        [max_duration]
FROM
       sys.query_store_query q
       JOIN sys.query_store_query_text t ON q.query_text_id = t.query_text_id
       JOIN sys.query_store_plan p ON p.query_id = q.query_id
       JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
WHERE
       --q.query_id = 71
        rs.avg_duration > 0
ORDER BY rs.max_duration DESC;
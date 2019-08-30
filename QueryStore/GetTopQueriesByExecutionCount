/*
	====================================
	   Top Queries By Execution Count
	====================================
	The following query will find the top 10 queries by execution count
*/
SELECT TOP 10
       q.query_id                    [query_id]
       , t.query_sql_text            [command]
       , SUM(rs.count_executions)    [execution_count]
FROM
       sys.query_store_query q
       JOIN sys.query_store_query_text t ON q.query_text_id = t.query_text_id
       JOIN sys.query_store_plan p ON p.query_id = q.query_id
       JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
GROUP BY
       q.query_id , t.query_sql_text ORDER BY 3 DESC;

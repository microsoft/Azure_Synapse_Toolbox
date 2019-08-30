/*
	===============================
	   Get Full Query Text
	===============================
	The following query will collect the full query text for a query out of the query store
    Filter on your query_id to see a particular query.
*/
SELECT
     q.query_id
     , t.query_sql_text
FROM
     sys.query_store_query q
     JOIN sys.query_store_query_text t ON q.query_text_id = t.query_text_id;

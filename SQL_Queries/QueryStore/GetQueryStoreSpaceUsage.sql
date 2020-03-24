/*
	========================================================
	   Get Query Store Space Usage
	========================================================
	 The following query will check current the Query Store size and 
     size limit.
     To clear space you can use: 
     ALTER DATABASE <db_name> SET QUERY_STORE CLEAR;  
*/
SELECT current_storage_size_mb, max_storage_size_mb   
FROM sys.database_query_store_options;  

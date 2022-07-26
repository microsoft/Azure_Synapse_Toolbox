/*
	========================================================
	   Get QUery Store State
	========================================================
	 The following query will determine if Query Store is currently active, 
     and whether it is currently collects runtime stats or not.
*/
SELECT actual_state, actual_state_desc, readonly_reason,   
    current_storage_size_mb, max_storage_size_mb  
FROM sys.database_query_store_options;  

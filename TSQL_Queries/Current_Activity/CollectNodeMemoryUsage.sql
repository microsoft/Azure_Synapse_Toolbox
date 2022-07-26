/*
	===============================
	   Node Memory Usage
	===============================
	The following query will show how much memory is currently in use by each 
    SQLDW node compared to the max for current DWU. 

    If memory utilization regularly hits it's limits during workload execution, 
    consider scaling up your data warehouse. 
*/
SELECT 
	pc1.cntr_value as Curr_Mem_KB, pc1.cntr_value/1024.0 as Curr_Mem_MB, 	(pc1.cntr_value/1048576.0) as Curr_Mem_GB, 
	pc2.cntr_value as Max_Mem_KB, 
	pc2.cntr_value/1024.0 as Max_Mem_MB, 
	(pc2.cntr_value/1048576.0) as Max_Mem_GB, 
	pc1.cntr_value * 100.0/pc2.cntr_value AS Memory_Utilization_Percentage, 
	pc1.pdw_node_id 
FROM 
	-- pc1: current memory 
	sys.dm_pdw_nodes_os_performance_counters AS pc1 
	-- pc2: total memory allowed for this SQL instance 
	JOIN sys.dm_pdw_nodes_os_performance_counters AS pc2 ON pc1.object_name = pc2.object_name 
	AND pc1.pdw_node_id = pc2.pdw_node_id 
WHERE pc1.counter_name = 'Total Server Memory (KB)' AND pc2.counter_name = 'Target Server Memory (KB)'

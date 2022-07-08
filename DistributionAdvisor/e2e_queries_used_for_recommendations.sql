DECLARE @NumMaxQueries int = 100; -- change this to match the variable in mvp script; looks at different numbers of queries.

-- the below where clauses should match those in the mvp script

with topnqueries as 
		(select top(@NumMaxQueries) command, COUNT(*) AS number_of_runs, SUM(total_elapsed_time) AS total_execution_time
		from sys.dm_pdw_exec_requests
		where
		command like '%select%' and
		command not like '%insert%' and 
		command not like '%USE [[]DWShellDb%\' and
		command not like '--Backing up Logical Azure Database%\' and
		command not like '%select % as ConnectionProtocol%' and
		command not like '%set recommendations on%' and 
		command not like '%set recommendations off%' and
		command not like 'USE [[]%]' and
		command not like '%sys.system_sql_modules%' and
		command not like '%sys.indexes%' and
		command not like '%merge%' and
		command not like '%CREATE%TABLE%' and
		command not like '%dm_pdw_exec_requests%' and
		command not like '%sys.databases%' and
		command not like '%trancount%' and command not like '%spid%' and
		total_elapsed_time > 300 and
		command not like '%SERVERPROPERTY%' and 
		resource_class != 'NULL' and
		command not like '%sys.objects%' and command not like '%sys.tables%' and command not like '%sys.schemas%' and command not like '%sys.dm_pdw_%' and
		status = 'Completed'
		GROUP BY command
		ORDER BY total_execution_time desc)
		select * from topnqueries;
/*
	================================
	   Check Status of DWU Change
	================================
	This query will check the status of the DWU change for the specified database
	It will either return IN_PROGRESS or COMPMLETED
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/what-is-a-data-warehouse-unit-dwu-cdwu
*/
SELECT    *
FROM      sys.dm_operation_status
WHERE     resource_type_desc = 'Database'
AND       major_resource_id = 'MySQLDW'
;
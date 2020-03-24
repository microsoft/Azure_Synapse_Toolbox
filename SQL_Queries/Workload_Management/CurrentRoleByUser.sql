/*
	==========================
	   Current Role By User
	==========================
	The following query returns what DWU role each user is currently assigned to.  
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/analyze-your-workload
*/
SELECT  r.name AS role_principal_name
,       m.name AS member_principal_name
FROM    sys.database_role_members rm
JOIN    sys.database_principals AS r            ON rm.role_principal_id      = r.principal_id
JOIN    sys.database_principals AS m            ON rm.member_principal_id    = m.principal_id
WHERE   r.name IN ('mediumrc','largerc','xlargerc')
;
/*
	========================================
	   Find Nullable Distribution Columns
	========================================

	This query will return any distribution columns in the Azure SQL Data Warehouse Database that are 
	set to allow NULLs. As a best practice and to avoid data skew, all distribution columns should be set to NOT NULL

	Author: Nicksalc@Microsoft.com
*/

SELECT
       s.name              as 'Schema Name',
       t.name              as 'Table Name',
       c.name              as 'Distribution Column',
       c.is_nullable,
       c.object_id
FROM sys.pdw_column_distribution_properties pcdp
JOIN sys.columns c
       ON pcdp.[object_id] = c.[object_id]
       AND pcdp.column_id = c.column_id
       AND pcdp.distribution_ordinal = 1
JOIN sys.tables t
       ON c.object_id = t.object_id
JOIN sys.schemas s
       ON t.schema_id = s.schema_id
WHERE c.is_nullable = 1

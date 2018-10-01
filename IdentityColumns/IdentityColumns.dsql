/*
	======================
	   Identity Columns
	======================
	This query will return information about identity columns for the given table.   
	See source link for more information.
	
	**Fill in Schema and Table information
	
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-tables-identity
*/
SELECT  sm.name
,       tb.name
,       co.name
,       CASE WHEN ic.column_id IS NOT NULL
             THEN 1
        ELSE 0
        END AS is_identity 
FROM        sys.schemas AS sm
JOIN        sys.tables  AS tb           ON  sm.schema_id = tb.schema_id
JOIN        sys.columns AS co           ON  tb.object_id = co.object_id
LEFT JOIN   sys.identity_columns AS ic  ON  co.object_id = ic.object_id
                                        AND co.column_id = ic.column_id
WHERE   sm.name = 'dbo'
AND     tb.name = 'T1'
;
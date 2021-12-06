/*
	=================================
	   CCI Trim Reason
	=================================
	This query reports the Trim Reason for the individual Compressed RowGoups.

*/
WITH 
    cte_All_RowGroups AS (
        SELECT  [Schema_Name], 
                [Table_Name],
                Distribution_Type,
                COUNT(*) AS rg_compressed_count_total
            FROM [dbo].[vCS_rg_physical_stats]
            WHERE rg_state = 3
            GROUP BY [Schema_Name], [Table_Name], Distribution_Type ),

    cte_Compressed_RowGroups AS (
        SELECT  [Schema_Name], 
                [Table_Name],
                rg_trim_reason      as trim_reason,
                rg_trim_reason_desc as trim_reason_desc,
                COUNT(*)            as trim_reason_rg_count
            FROM [dbo].[vCS_rg_physical_stats]
            WHERE rg_state = 3
            GROUP BY [Schema_Name], [Table_Name], rg_trim_reason, rg_trim_reason_desc )

SELECT  
        SYSDATETIME() as 'Collection_Date',
        DB_Name(),
        a.*,
        c.trim_reason,
        c.trim_reason_desc,
        c.trim_reason_rg_count
    FROM cte_All_RowGroups a
        LEFT OUTER JOIN cte_Compressed_RowGroups c
            ON  a.[Schema_Name] = c.[Schema_Name]
            AND a.[Table_Name]  = c.[Table_Name]
    ORDER BY a.[Schema_Name], a.[Table_Name], c.trim_reason


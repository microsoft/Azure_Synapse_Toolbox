--Table space by index type
--PRE-REQUISITE: MUST HAVE TABLE INFO VIEW CREATED ALREADY
--SOURCE: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-tables-overview#table-size-queries
SELECT 
     index_type_desc
,    SUM(row_count)                as table_type_row_count
,    SUM(reserved_space_GB)        as table_type_reserved_space_GB
,    SUM(data_space_GB)            as table_type_data_space_GB
,    SUM(index_space_GB)           as table_type_index_space_GB
,    SUM(unused_space_GB)          as table_type_unused_space_GB
FROM dbo.vTableSizes
GROUP BY index_type_desc
;
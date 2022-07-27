-- Create Separate Schema For loading all Tables 
CREATE SCHEMA SynapseAnalyzer
GO 

-- All_Tables

IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'All_Tables' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.All_Tables
END

GO

CREATE TABLE SynapseAnalyzer.All_Tables
WITH (Clustered Index([two_part_name], s_key), DISTRIBUTION = REPLICATE)
AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY [two_part_name] ASC)         AS s_key
,   GETDATE()                                               AS [execution_time]
,   [database_name]
,   [schema_name]
,   [table_name]
,   [table_object_id]
,   [is_external_table]
,   [two_part_name]
,   [three_part_name]
FROM (
    SELECT 
        DB_NAME()                        AS [database_name]
    ,   sm.[name]                        AS [schema_name]
    ,   tb.[name]                        AS [table_name]
    ,   tb.object_id                     AS [table_object_id]
    ,   QUOTENAME(sm.[name]) + '.' + QUOTENAME(tb.[name])   AS two_part_name
    ,   QUOTENAME(DB_NAME()) + '.' + QUOTENAME(sm.[name]) + '.' + QUOTENAME(tb.[name]) AS three_part_name
    ,   CASE WHEN et.object_id IS NULL THEN 0 ELSE 1 END AS is_external_table
    FROM    sys.tables AS tb 
        JOIN    sys.schemas AS sm 
                ON  tb.[schema_id]        = sm.[schema_id]
        LEFT OUTER JOIN sys.external_tables et ON tb.object_id = et.object_id
) All_Tables

GO

-- ColumnstoreDensity

IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'ColumnstoreDensity' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.ColumnstoreDensity
END

GO

CREATE TABLE SynapseAnalyzer.ColumnstoreDensity
WITH (Clustered Index ([TwoPartName]), DISTRIBUTION = REPLICATE)
AS
SELECT
		QUOTENAME(s.name)+'.'+QUOTENAME(t.name)									AS [TwoPartName]
,        GETDATE()                                                               AS [execution_date]
,       DB_Name()                                                               AS [database_name]
,       s.name                                                                  AS [schema_name]
,       t.name                                                                  AS [table_name]
,    COUNT(DISTINCT rg.[partition_number])                    AS [table_partition_count]
,       SUM(rg.[total_rows])                                                    AS [row_count_total]
,       SUM(rg.[total_rows])/COUNT(DISTINCT rg.[distribution_id])               AS [row_count_per_distribution_MAX]
,    CEILING    ((SUM(rg.[total_rows])*1.0/COUNT(DISTINCT rg.[distribution_id]))/1048576) AS [rowgroup_per_distribution_MAX]
,       SUM(CASE WHEN rg.[State] = 0 THEN 1                   ELSE 0    END)    AS [INVISIBLE_rowgroup_count]
,       SUM(CASE WHEN rg.[State] = 0 THEN rg.[total_rows]     ELSE 0    END)    AS [INVISIBLE_rowgroup_rows]
,       MIN(CASE WHEN rg.[State] = 0 THEN rg.[total_rows]     ELSE NULL END)    AS [INVISIBLE_rowgroup_rows_MIN]
,       MAX(CASE WHEN rg.[State] = 0 THEN rg.[total_rows]     ELSE NULL END)    AS [INVISIBLE_rowgroup_rows_MAX]
,       AVG(CASE WHEN rg.[State] = 0 THEN rg.[total_rows]     ELSE NULL END)    AS [INVISIBLE_rowgroup_rows_AVG]
,       SUM(CASE WHEN rg.[State] = 1 THEN 1                   ELSE 0    END)    AS [OPEN_rowgroup_count]
,       SUM(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE 0    END)    AS [OPEN_rowgroup_rows]
,       MIN(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE NULL END)    AS [OPEN_rowgroup_rows_MIN]
,       MAX(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE NULL END)    AS [OPEN_rowgroup_rows_MAX]
,       AVG(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE NULL END)    AS [OPEN_rowgroup_rows_AVG]
,       SUM(CASE WHEN rg.[State] = 2 THEN 1                   ELSE 0    END)    AS [CLOSED_rowgroup_count]
,       SUM(CASE WHEN rg.[State] = 2 THEN rg.[total_rows]     ELSE 0    END)    AS [CLOSED_rowgroup_rows]
,       MIN(CASE WHEN rg.[State] = 2 THEN rg.[total_rows]     ELSE NULL END)    AS [CLOSED_rowgroup_rows_MIN]
,       MAX(CASE WHEN rg.[State] = 2 THEN rg.[total_rows]     ELSE NULL END)    AS [CLOSED_rowgroup_rows_MAX]
,       AVG(CASE WHEN rg.[State] = 2 THEN rg.[total_rows]     ELSE NULL END)    AS [CLOSED_rowgroup_rows_AVG]
,       SUM(CASE WHEN rg.[State] = 3 THEN 1                   ELSE 0    END)    AS [COMPRESSED_rowgroup_count]
,       SUM(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE 0    END)    AS [COMPRESSED_rowgroup_rows]
,       SUM(CASE WHEN rg.[State] = 3 THEN rg.[deleted_rows]   ELSE 0    END)    AS [COMPRESSED_rowgroup_rows_DELETED]
,       MIN(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE NULL END)    AS [COMPRESSED_rowgroup_rows_MIN]
,       MAX(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE NULL END)    AS [COMPRESSED_rowgroup_rows_MAX]
,       AVG(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE NULL END)    AS [COMPRESSED_rowgroup_rows_AVG]
,       'ALTER INDEX ALL ON ' + s.name + '.' + t.NAME + ' REBUILD;'             AS [Rebuild_Index_SQL]
FROM    sys.[pdw_nodes_column_store_row_groups] rg
JOIN    sys.[pdw_nodes_tables] nt                   ON  rg.[object_id]          = nt.[object_id]
                                                    AND rg.[pdw_node_id]        = nt.[pdw_node_id]
                                                    AND rg.[distribution_id]    = nt.[distribution_id]
JOIN    sys.[pdw_table_mappings] mp                 ON  nt.[name]               = mp.[physical_name]
JOIN    sys.[tables] t                              ON  mp.[object_id]          = t.[object_id]
JOIN    sys.[schemas] s                             ON t.[schema_id]            = s.[schema_id]
GROUP BY
        s.[name]
,       t.[name];

-- StatsSummary

IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'StatsSummary' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.StatsSummary
END

GO

CREATE TABLE SynapseAnalyzer.StatsSummary
WITH (Clustered Index ([two_part_name]), DISTRIBUTION = REPLICATE)
AS
WITH 
StatsColumns
AS ( 
    SELECT 
        c.object_id
    ,   s.stats_id
    ,   s.name  
    ,   STRING_AGG(QUOTENAME(c.name),',') Stat_Columns
    ,   count(1) NumberOfColumns 
    FROM sys.stats s 
        JOIN sys.stats_columns sc   ON s.object_id = sc.object_id 
                                    AND s.stats_id = sc.stats_id
        JOIN sys.columns c          ON c.object_id = s.object_id 
                                    AND c.column_id = sc.column_id
    WHERE (s.auto_created = 1 OR s.user_created = 1)
    GROUP BY c.object_id, s.stats_id, s.name
)
SELECT 
 GETDATE()                                              AS  [execution_time]
, DB_NAME()                                             AS  [database_name]
, s.name                                                AS  [schema_name]
, t.name                                                AS  [table_name]
, QUOTENAME(s.name)+'.'+QUOTENAME(t.name)               AS  [two_part_name]
, sc.name                                               AS  [stat_name]
, STATS_DATE(sc.[object_id],sc.[stats_id])              AS  [stats_last_updated_date]
, sc.Stat_Columns                                       AS  [stat_column_list]
, sc.NumberOfColumns                                    AS  [no_of_columns]
FROM sys.schemas s
	JOIN sys.tables t ON t.schema_id=s.schema_id
	JOIN sys.indexes i ON i.object_id=t.object_id AND i.index_id<2
	JOIN StatsColumns sc ON sc.object_id=t.object_id 


-- TableSizes

IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'TableSizes' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.TableSizes
END

GO

CREATE TABLE SynapseAnalyzer.TableSizes
WITH (Clustered Index ([two_part_name],[distribution_id]), DISTRIBUTION = HASH(distribution_id) )
AS
WITH base
AS
(
SELECT
 GETDATE()                                                             AS  [execution_time]
, DB_NAME()                                                            AS  [database_name]
, s.name                                                               AS  [schema_name]
, t.name                                                               AS  [table_name]
, QUOTENAME(s.name)+'.'+QUOTENAME(t.name)                              AS  [two_part_name]
, nt.[name]                                                            AS  [node_table_name]
, ROW_NUMBER() OVER(PARTITION BY nt.[name] ORDER BY (SELECT NULL))     AS  [node_table_name_seq]
, tp.[distribution_policy_desc]                                        AS  [distribution_policy_name]
, c.[name]                                                             AS  [distribution_column]
, nt.[distribution_id]                                                 AS  [distribution_id]
, i.[index_id]                                                         AS  [index_id]
, i.[type]                                                             AS  [index_type]
, i.[type_desc]                                                        AS  [index_type_desc]
, nt.[pdw_node_id]                                                     AS  [pdw_node_id]
, pn.[type]                                                            AS  [pdw_node_type]
, pn.[name]                                                            AS  [pdw_node_name]
, di.name                                                              AS  [dist_name]
, di.position                                                          AS  [dist_position]
, nps.[partition_number]                                               AS  [partition_nmbr]
, nps.[reserved_page_count]                                            AS  [reserved_space_page_count]
, nps.[reserved_page_count] - nps.[used_page_count]                    AS  [unused_space_page_count]
, nps.[in_row_data_page_count]
    + nps.[row_overflow_used_page_count]
    + nps.[lob_used_page_count]                                        AS  [data_space_page_count]
, nps.[reserved_page_count]
 - (nps.[reserved_page_count] - nps.[used_page_count])
 - ([in_row_data_page_count]
         + [row_overflow_used_page_count]+[lob_used_page_count])       AS  [index_space_page_count]
, nps.[row_count]                                                      AS  [row_count]
from
    sys.schemas s
INNER JOIN sys.tables t
    ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.indexes i
    ON  t.[object_id] = i.[object_id]
INNER JOIN sys.pdw_table_distribution_properties tp
    ON t.[object_id] = tp.[object_id]
INNER JOIN sys.pdw_table_mappings tm
    ON t.[object_id] = tm.[object_id]
INNER JOIN sys.pdw_nodes_tables nt
    ON tm.[physical_name] = nt.[name]
INNER JOIN sys.dm_pdw_nodes pn
    ON  nt.[pdw_node_id] = pn.[pdw_node_id]
INNER JOIN sys.pdw_distributions di
    ON  nt.[distribution_id] = di.[distribution_id]
INNER JOIN sys.dm_pdw_nodes_db_partition_stats nps
    ON nt.[object_id] = nps.[object_id]
    AND  i.[index_id] = nps.[index_id]
    AND nt.[pdw_node_id] = nps.[pdw_node_id]
    AND nt.[distribution_id] = nps.[distribution_id]
LEFT OUTER JOIN (select * from sys.pdw_column_distribution_properties where distribution_ordinal = 1) cdp
    ON t.[object_id] = cdp.[object_id]
LEFT OUTER JOIN sys.columns c
    ON cdp.[object_id] = c.[object_id]
    AND cdp.[column_id] = c.[column_id]
WHERE pn.[type] = 'COMPUTE'
)
SELECT
   [execution_time]
,  [database_name]
,  [schema_name]
,  [table_name]
,  [two_part_name]
,  [node_table_name]
,  [node_table_name_seq]
,  [distribution_policy_name]
,  [distribution_column]
,  [distribution_id]
,  [index_id]
,  [index_type]
,  [index_type_desc]
,  [pdw_node_id]
,  [pdw_node_type]
,  [pdw_node_name]
,  [dist_name]
,  [dist_position]
,  [partition_nmbr]
,  [reserved_space_page_count]
,  [unused_space_page_count]
,  [data_space_page_count]
,  [index_space_page_count]
,  [row_count]
,  ([reserved_space_page_count] * 8.0)                                 AS [reserved_space_KB]
,  ([unused_space_page_count]   * 8.0)                                 AS [unused_space_KB]
,  ([data_space_page_count]     * 8.0)                                 AS [data_space_KB]
,  ([index_space_page_count]  * 8.0)                                   AS [index_space_KB]
FROM base



-- StatColumns

IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'StatColumns' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.StatColumns
END

GO

CREATE TABLE SynapseAnalyzer.StatColumns
WITH (Clustered Index ([two_part_name]), DISTRIBUTION = ROUND_ROBIN )
AS
SELECT
        GETDATE()                           AS  [execution_time]
,       DB_NAME()                           AS  [database_name]       
,       sm.[name]                           AS [schema_name]
,       tb.[name]                           AS [table_name]
,       st.[name]                           AS [stats_name]
,       st.[filter_definition]              AS [stats_filter_definition]
,       st.[has_filter]                     AS [stats_is_filtered]
,       STATS_DATE(st.[object_id],st.[stats_id])
                                            AS [stats_last_updated_date]
,       co.[name]                           AS [stats_column_name]
,       ty.[name]                           AS [column_type]
,       co.[max_length]                     AS [column_max_length]
,       co.[precision]                      AS [column_precision]
,       co.[scale]                          AS [column_scale]
,       co.[is_nullable]                    AS [column_is_nullable]
,       co.[collation_name]                 AS [column_collation_name]
,       QUOTENAME(sm.[name])+'.'+QUOTENAME(tb.[name])
                                            AS two_part_name
,       QUOTENAME(DB_NAME())+'.'+QUOTENAME(sm.[name])+'.'+QUOTENAME(tb.[name])
                                            AS three_part_name
FROM    sys.objects                         AS ob
JOIN    sys.stats           AS st ON    ob.[object_id]      = st.[object_id]
JOIN    sys.stats_columns   AS sc ON    st.[stats_id]       = sc.[stats_id]
                            AND         st.[object_id]      = sc.[object_id]
JOIN    sys.columns         AS co ON    sc.[column_id]      = co.[column_id]
                            AND         sc.[object_id]      = co.[object_id]
JOIN    sys.types           AS ty ON    co.[user_type_id]   = ty.[user_type_id]
JOIN    sys.tables          AS tb ON  co.[object_id]        = tb.[object_id]
JOIN    sys.schemas         AS sm ON  tb.[schema_id]        = sm.[schema_id]
WHERE   1=1
AND      (st.user_created = 1 OR st.auto_created = 1)

-- ControlNodeRowcount


IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'ControlNodeRowcount' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.ControlNodeRowcount
END

GO

CREATE TABLE SynapseAnalyzer.ControlNodeRowcount
WITH (Clustered Index ([two_part_name]), DISTRIBUTION = ROUND_ROBIN )
AS
WITH CtlSummary
AS 
( 
    SELECT 
        p.object_id
    ,   p.index_id    
    ,   p.partition_number
    ,   SUM(p.rows) rows

    FROM sys.partitions p
    WHERE p.index_id < 2
    GROUP BY p.object_id, p.partition_number,p.index_id 
)
SELECT 
 GETDATE()                                                             AS  [execution_time]
, DB_NAME()                                                            AS  [database_name]
, s.name                                                               AS  [schema_name]
, t.name                                                               AS  [table_name]
, QUOTENAME(s.name)+'.'+QUOTENAME(t.name)                              AS  [two_part_name]
, i.type_desc                                                          AS  [table_type]
, p.partition_number                                                   AS  [partition_number]
, p.rows                                                               AS  [Stats_rowcount]
FROM sys.schemas s
	JOIN sys.tables t ON t.schema_id=s.schema_id
	JOIN sys.indexes i ON i.object_id=t.object_id AND i.index_id<2
	JOIN CtlSummary p ON p.object_id=t.object_id AND p.index_id=i.index_id





--ColumnStoreRowGroupPhysicalStats
IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'ColumnStoreRowGroupPhysicalStats' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.ColumnStoreRowGroupPhysicalStats
END

GO

CREATE TABLE SynapseAnalyzer.ColumnStoreRowGroupPhysicalStats
WITH (Clustered Index ([two_part_name],index_id,row_group_id), DISTRIBUTION = ROUND_ROBIN)
AS
SELECT   tb.[name]                                     AS [logical_table_name]
,        sm.[name]                                     AS [schema_name]
,        QUOTENAME(sm.name)+'.'+QUOTENAME(tb.name)     AS [two_part_name]
,	 rg.[index_id]				       AS [index_id]
,	 rg.[partition_number]			       AS [partition_number]
,        rg.[row_group_id]                             AS [row_group_id]
,        rg.[state]                                    AS [state]
,        rg.[state_desc]                               AS [state_desc]
,        rg.[total_rows]                               AS [total_rows]
,	 rg.[deleted_rows]			       AS [deleted_rows]
,	 rg.[size_in_bytes]			       AS [size_in_bytes]
,        COALESCE(rg.[trim_reason_desc], rg.[state_desc])AS trim_reason_desc
,        mp.[physical_name]                            AS physical_name
FROM    sys.[schemas] sm
JOIN    sys.[tables] tb               ON  sm.[schema_id]          = tb.[schema_id]
JOIN    sys.[pdw_table_mappings] mp   ON  tb.[object_id]          = mp.[object_id]
JOIN    sys.[pdw_nodes_tables] nt     ON  nt.[name]               = mp.[physical_name]
JOIN    sys.[dm_pdw_nodes_db_column_store_row_group_physical_stats] rg      ON  rg.[object_id]     = nt.[object_id]
                                                                            AND rg.[pdw_node_id]   = nt.[pdw_node_id]
                                        AND rg.[distribution_id]    = nt.[distribution_id]





--ExternalTables


IF Exists(SELECT [name]
    FROM sys.tables
    WHERE [name] like 'ExternalTables' AND schema_id = SCHEMA_ID('SynapseAnalyzer'))
BEGIN
     DROP TABLE SynapseAnalyzer.ExternalTables
END

GO

CREATE TABLE SynapseAnalyzer.ExternalTables
WITH (Clustered Index ([two_part_name]), DISTRIBUTION = REPLICATE )
AS
SELECT 
    GETDATE()                        AS  [execution_time]
,   DB_NAME()                        AS [database_name]
,   sm.[name]                        AS [schema_name]
,   et.[name]                        AS [table_name]
,   et.object_id                     AS [table_object_id]
,   et.type_desc	
,   et.max_column_id_used	
,   et.uses_ansi_nulls	
,   et.data_source_id	
,   et.file_format_id	
,   et.location
,   QUOTENAME(sm.[name]) + '.' + QUOTENAME(et.[name])   AS two_part_name
FROM    sys.external_tables AS et 
    JOIN    sys.schemas AS sm 
        ON  et.[schema_id]        = sm.[schema_id]



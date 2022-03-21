--Get all stats that exist

Select 
    db_name() as [Database]
    , sch.name as [Schema]
    , t.name as [Table]
    , t.object_id as Table_ID
    , s.name as [Statistic]
    , s.stats_id as stats_id
    , c.name as [Column]
    , c.column_id as column_id
From sys.tables t
	inner join sys.stats s
		on t.object_id = s.object_id
	inner join sys.stats_columns sc
		on t.object_id = sc.object_id
			and s.stats_id = sc.stats_id
	inner join sys.columns c
		on sc.column_id = c.column_id
			and t.object_id = c.object_id
    inner join sys.schemas sch
        ON t.schema_id = sch.schema_id
WHERE 1=1
--AND sch.name like '%dbo%' --uncomment to choose a schema
--AND t.name like '%Trips%' --Uncomment to pick a specific table
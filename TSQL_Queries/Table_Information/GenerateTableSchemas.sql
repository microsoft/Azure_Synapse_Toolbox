--Generate Schemas of all tables
--This is an early release that may not cover all data types or table structures and should not be considered perfect
WITH ColumnList AS
(	select s.name AS 'Schema'
	,t.name AS 'Table'
	,c.name AS 'Column'
	,c.column_id
	,type.name AS 'Type'
	,c.max_length
	,c.precision
	,c.scale
	,c.is_nullable 
	, ColumnDefinition = 
		CASE 
			WHEN type.name in ('varchar')  AND c.is_nullable=1 THEN '[' + c.name + '] ' + type.name + '(' + cast(c.max_length as nvarchar(5)) + ') NULL,'
			WHEN type.name in ('varchar')  AND c.is_nullable=0 THEN '[' + c.name + '] ' + type.name + '(' + cast(c.max_length as nvarchar(5)) + ') NOT NULL,'
			WHEN type.name in ('nvarchar')  AND c.is_nullable=1 THEN '[' + c.name + '] ' + type.name + '(' + cast(c.max_length/2 as nvarchar(5)) + ') NULL,'
			WHEN type.name in ('nvarchar')  AND c.is_nullable=0 THEN '[' + c.name + '] ' + type.name + '(' + cast(c.max_length/2 as nvarchar(5)) + ') NOT NULL,'
			WHEN type.name in ('real','int','datetime','bigint','bit','smallint','tinyint','smallmoney','money','float','sysname','date')  AND c.is_nullable=0 THEN '[' + c.name + '] ' + type.name + ' NOT NULL,'
			WHEN type.name in ('real','int','datetime','bigint','bit','smallint','tinyint','smallmoney','money','float','sysname','date')  AND c.is_nullable=1 THEN '[' + c.name + '] ' + type.name + ' NULL,'
			WHEN type.name in ('numeric','decimal')  AND c.is_nullable=0 THEN '[' + c.name + '] ' + type.name + '(' + cast(c.precision  as nvarchar(5)) + ', ' + cast(c.scale  as nvarchar(5)) + ') NOT NULL,'
			WHEN type.name in ('numeric','decimal')  AND c.is_nullable=1 THEN '[' + c.name + '] ' + type.name + '(' + cast(c.precision  as nvarchar(5)) + ', ' + cast(c.scale  as nvarchar(5)) + ') NULL,'
			ELSE '--no match--'
		END
	, CTAS_Version = 
		CASE 
			WHEN type.name in ('varchar','nvarchar') THEN 'ISNULL([' + c.name + '],'''') AS [' + c.name + '],'
			ELSE '[' + c.name  + '],'
		END
	from sys.tables t
	join sys.schemas s
	on t.schema_id = s.schema_id
	join sys.columns c
	on t.object_id = c.object_id
	join sys.types type
	on c.user_type_id = type.user_type_id
)

SELECT
	s.name AS 'Schema'
	,t.name AS 'Table'
	,t.object_id
	,ptdp.Distribution_policy_desc AS 'Table_Type' 
	,dist.column_name AS Distribution_Column
	,i.name AS Index_name
	,ISNULL(i.type_desc,'HEAP') AS Index_Type
	--,ic.column_id as 'Index_Column_ID'
	,CL.[Column]
	,CL.column_id
	,i.index_id
	,CL.[Type]
	,CL.max_length
	,CL.precision
	,CL.scale
	,CL.is_nullable 
	,CL.ColumnDefinition
	,CL.Ctas_version
	,t.create_date
	,t.modify_date
FROM sys.tables t
JOIN sys.schemas s
ON t.schema_id = s.schema_id
JOIN sys.pdw_table_distribution_properties ptdp
ON t.object_id = ptdp.object_id
LEFT JOIN (
	select c.name as column_name,pcdp.distribution_ordinal,c.object_id from sys.pdw_column_distribution_properties pcdp
	join sys.columns c
	ON pcdp.[object_id] = c.[object_id]
	AND pcdp.column_id = c.column_id
	AND pcdp.distribution_ordinal = 1
	) as Dist
ON ptdp.object_id = dist.object_id
JOIN ColumnList CL
ON CL.[schema] = s.[name]
AND t.[name] = CL.[table]
LEFT JOIN sys.index_columns ic
on t.object_id = ic.object_id
AND CL.column_id = ic.column_id
LEFT JOIN sys.indexes i
ON ic.object_id = i.object_id
AND ic.index_id = i.index_id
ORDER BY [schema],[Table]
	
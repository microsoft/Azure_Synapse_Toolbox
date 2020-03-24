--Table Information query
SELECT
	t.name AS 'Table_Name',
	t.object_id,
	t.create_date,
	t.modify_date,
	ptdp.Distribution_policy_desc AS 'Table_Type', 
	dist.column_name AS Distribution_Column,
	i.name AS Index_name,
	i.type_desc AS Index_Type
FROM sys.tables t
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
JOIN sys.indexes i
ON t.object_id = i.object_id
ORDER BY Table_Name 
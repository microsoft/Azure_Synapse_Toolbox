select c.name
from sys.index_columns ic
join sys.tables t on t.object_id = ic.object_id
join sys.columns c
on c.object_id = ic.object_id and c.column_id = ic.column_id
where ic.partition_ordinal > 0
and t.object_id  = (select object_id from sys.objects where name =  'FactInternetSalespartition')
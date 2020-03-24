/*
	====================================
	   Missing or Outdated Statistics 
	====================================

	This query will return stats that are determined to be needed or out of date. 

	*results are only returned for tables with more than 1 million rows. You can edit this by changing the @minRows variable

	Data Skew - Data returned where skew is greater than 10%
	Missing stats - Data returned where the control node number of rows is 1,000 (the default value when there are no statistics)
	Outdated Stats - Data returned when the difference between the statistics rowcount and actual rowcount is greater than 20%
*/

declare @minRows int=1000000;
declare @minSkewPercent decimal=10.0;
declare @missingStatCtlRowCount int=1000;
declare @CtlCmpRowDifferencePercentageForOutdatedStats decimal=20.0;

with cmp_details as
(
	select tm.object_id, ps.distribution_id, count(ps.partition_number) [partitions], sum(ps.row_count) cmp_row_count
	from sys.dm_pdw_nodes_db_partition_stats ps
		join sys.pdw_nodes_tables nt on nt.object_id=ps.object_id and ps.distribution_id=nt.distribution_id
		join sys.pdw_table_mappings tm on tm.physical_name=nt.name
	group by tm.object_id, ps.distribution_id
)
, cmp_summary as
(
	select object_id, sum(cmp_row_count) cmp_row_count
		 , (max(cmp_row_count)-min(cmp_row_count)) highest_skew_rows_difference
		 , convert(decimal(10,2),((max(cmp_row_count) - min(cmp_row_count))*100.0 / nullif(sum(cmp_row_count),0))) skew_percent
	from cmp_details
	group by object_id
)
, ctl_summary as
(
	select t.object_id, s.name sch_name, t.name table_name, i.type_desc table_type, dp.distribution_policy_desc distribution_type, count(p.partition_number) [partitions], sum(p.rows) ctl_row_count
	from sys.schemas s
		join sys.tables t on t.schema_id=s.schema_id
		join sys.pdw_table_distribution_properties dp on dp.object_id=t.object_id
		join sys.indexes i on i.object_id=t.object_id and i.index_id<2
		join sys.partitions p on p.object_id=t.object_id and p.index_id=i.index_id
	group by t.object_id, s.name, t.name, i.type_desc, dp.distribution_policy_desc
)
, [all_results] as
(
	select ctl.object_id, ctl.sch_name, ctl.table_name, ctl.table_type, ctl.distribution_type, ctl.[partitions]
		, ctl.ctl_row_count, cmp.cmp_row_count, convert(decimal(10,2),(abs(ctl.ctl_row_count - cmp.cmp_row_count)*100.0 / nullif(cmp.cmp_row_count,0))) ctl_cmp_difference_percent
		, cmp.highest_skew_rows_difference, cmp.skew_percent
		, case 
			when (ctl.ctl_row_count = @missingStatCtlRowCount) then 'missing stats'
			when ((ctl.ctl_row_count <> cmp.cmp_row_count) and ((abs(ctl.ctl_row_count - cmp.cmp_row_count)*100.0 / nullif(cmp.cmp_row_count,0)) > @CtlCmpRowDifferencePercentageForOutdatedStats)) then 'outdated stats'
			else null
		  end stat_info
		, case when (cmp.skew_percent >= @minSkewPercent) then 'data skew' else null end skew_info
	from ctl_summary ctl
		join cmp_summary cmp on ctl.object_id=cmp.object_id
)
select *
from [all_results]
where cmp_row_count>@minRows and (stat_info is not null or skew_info is not null)
order by sch_name, table_name
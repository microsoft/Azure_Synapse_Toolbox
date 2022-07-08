IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.write_dist_recommendation'))
	DROP PROCEDURE dbo.write_dist_recommendation
go

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.read_dist_recommendation'))
	DROP PROCEDURE dbo.read_dist_recommendation
go

CREATE PROCEDURE write_dist_recommendation
	@NumMaxQueries int, 
	@Queries NVARCHAR(MAX)
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	DECLARE @sessionid nvarchar(max) = SESSION_ID();
	DECLARE @guid nvarchar(100) = REPLACE(NEWID(), '-', '');
	DECLARE @guidpusher nvarchar(max) = CONCAT(N'    --distrib_advisor_correlation_id_', @guid, CHAR(13), CHAR(10));
	DECLARE @recostring nvarchar(max);
	DECLARE @TempTableName nvarchar(max) = CONCAT(N'DistributionAdvisorGUIDs', @sessionid);
	DECLARE @InsertGuid nvarchar(max) = CONCAT(N'insert into ', @TempTableName, N' values(''', @guid, N''')');
	DECLARE @CreateTempTable nvarchar(max) = CONCAT(N'create table ', @TempTableName, N'(xguid nvarchar(100)) with(distribution = ROUND_ROBIN);');
	DECLARE @DeleteTempTable nvarchar(max) = CONCAT(N'if exists (select * from sys.tables where name = ''', @TempTableName, N''') drop table ', @TempTableName);
	if not exists ( select * from sys.tables where name = 'DistributionAdvisorSelectedQueries')
		create table DistributionAdvisorSelectedQueries(command nvarchar(4000), tot_te bigint) with(clustered columnstore index, distribution = ROUND_ROBIN);

	-- command not like ''%--%'' and -- removes comments
	IF (@Queries is NULL)
		BEGIN
			if (@NumMaxQueries is NULL or @NumMaxQueries < 1 or @NumMaxQueries > 100)
				BEGIN
					RAISERROR(N'Max queries value must be in [1...100] range, changing to 100.', 0, -1);
					SET @NumMaxQueries = 100;
				END
			SET @sql = 'with topnqueries as 
					(select top(@nmq) command, MIN(total_elapsed_time) AS min_te, AVG(total_elapsed_time) AS avg_te, COUNT(*) AS num_runs, SUM(total_elapsed_time) AS tot_te
					from (select command = case when command2 is null then command else command2 end, total_elapsed_time
					from sys.dm_pdw_exec_requests
					where
						command not like ''%USE [[]DWShellDb%\'' and
						command not like ''%DistributionAdvisor%'' and
						command not like ''--Backing up Logical Azure Database%\'' and
						command not like ''%select % as ConnectionProtocol%'' and
						command like ''%select%'' and
						command not like ''%set recommendations%'' and 
						command not like ''USE [[]%]'' and
						command not like ''%sys.system_sql_modules%'' and
						command not like ''%insert%'' and
						command not like ''%sys.indexes%'' and
						command not like ''%merge%'' and
						command not like ''%CREATE%TABLE%'' and
						command not like ''%dm_pdw_exec_requests%'' and
						command not like ''%sys.databases%'' and
						command not like ''%trancount%'' and 
						command not like ''%spid%'' and total_elapsed_time > 300 and
						command not like ''%SERVERPROPERTY%'' and resource_class != ''NULL'' and
						command not like ''%sys.objects%'' and 
						command not like ''%sys.tables%'' and 
						command not like ''%sys.schemas%'' and 
						command not like ''%sys.dm_pdw_%'' and
						status = ''Completed'') x
					GROUP BY command
					ORDER BY tot_te desc),
				allqueries as (select command, tot_te from topnqueries union all select * from DistributionAdvisorSelectedQueries),
				allqueriesgrouped as (select command, sum(tot_te) as tot_te from allqueries group by command),
				topnqueriesranked as (select REPLACE(command, '''''';'''''', ''CHAR(59)'') as command, tot_te, row_number() over (order by tot_te desc) as rn from allqueriesgrouped)
			select @recostring = 
			''set recommendations on;'' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
			+ ''/****************** Actual queries follow ****************************/'' + CHAR(13) + CHAR(10) +
			STRING_AGG(
				''/************************** Query q'' + cast (rn-1 as nvarchar(max)) + '' ********************************/'' + CHAR(13) + CHAR(10) + 
				(case 
				when charindex('';'', command) > 0 
				then REPLACE(REPLACE(cast(command AS nvarchar(max)), ''--distrib_advisor_correlation_id_'', ''--''), '';'', @guidpusher)
				else concat(command, @guidpusher)
				end),
				'';'' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)) +
			 + CHAR(13) + CHAR(10) + ''/******************** End actual queries **************************/'' + CHAR(13) + CHAR(10) +
			''set recommendations off;''
			from topnqueriesranked';
			END
	ELSE
		BEGIN
			SET @NumMaxQueries = 100;
			SET @Queries = REPLACE(@Queries, ''';''', 'char(59)');
			SET @sql = 'with userqueries as 
						(select CONCAT(value,'';'') as command, ordinal as tot_te
						from STRING_SPLIT(@customQueries, '';'', 1) where trim(value) <> '''' union all select * from DistributionAdvisorSelectedQueries),
						topnqueriesranked as (select *, row_number() over (order by tot_te desc) as rn from userqueries)
						select @recostring = 
						''set recommendations on;'' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
						+ ''/****************** Actual queries follow ****************************/'' + CHAR(13) + CHAR(10) +
						STRING_AGG(
							''/************************** Query q'' + cast (rn-1 as nvarchar(max)) + '' ********************************/'' + CHAR(13) + CHAR(10) + 
							(case 
							when charindex('';'', command) > 0 
							then REPLACE(REPLACE(cast(command AS nvarchar(max)), ''--distrib_advisor_correlation_id_'', ''--''), '';'', @guidpusher)
							else concat(command, @guidpusher)
							end),
							'';'' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)) +
						 + CHAR(13) + CHAR(10) + ''/******************** End actual queries **************************/'' + CHAR(13) + CHAR(10) +
						''set recommendations off;''
						from topnqueriesranked';
			END

	EXEC(@DeleteTempTable);
	EXEC sp_executesql @sql, N'@recostring nvarchar(max) OUTPUT, @guidpusher nvarchar(max), @nmq int, @customQueries nvarchar(max)', @recostring OUTPUT, @guidpusher, @NumMaxQueries, @Queries;

	IF (@recostring is null or len(@recostring) = 0)
	BEGIN
		RAISERROR(N'Cannot construct the set of queries to feed to advisor. This often happens if there are not enough queries in sys.dm_pdw_exec_requests.', 18, -1);
	END
	ELSE
		BEGIN
			SELECT @recostring AS Command_To_Invoke_Distribution_Advisor;

			-- this part invokes the advisor
			EXEC sp_executesql @recostring;

			EXEC(@CreateTempTable);
			EXEC(@InsertGuid);
			RAISERROR(N'Please use ''read_dist_recommendation'' stored procedure after recommendation is created to retrieve it', 0, -1);
		END
END
GO

-- This stored procedure reads the recommendation advice generated in write_dist_recommendation.
CREATE PROCEDURE read_dist_recommendation
AS BEGIN
	
	DECLARE @guidOut nvarchar(100);
	DECLARE @sessionid nvarchar(max) = SESSION_ID();
	DECLARE @TempTableName nvarchar(max) = CONCAT(N'DistributionAdvisorGUIDs', @sessionid);
	DECLARE @readerstring nvarchar(max) = CONCAT(N'with topguid as (SELECT TOP 1 * FROM ', @TempTableName, N') SELECT @guid = xguid from topguid');

	-- get the answer from ring buffer; we may have to wait a bit, so we do a few tries for the ring buffer to get ready
	DECLARE @recommendation nvarchar(max);
	DECLARE @corrid nvarchar(100);
	DECLARE @readrecommendation nvarchar(max) = N'select @recommendation = recommendation, @corrid = correlation_id from sys.dm_pdw_distrib_advisor_results ';
	DECLARE @DelayStart datetime = GETDATE();

	IF NOT EXISTS (select * from sys.tables where name = @TempTableName )
		BEGIN
			RAISERROR(N'GUID could not be retrieved. ''read_dist_recommendation'' stored procedure must run after write_dist_recommendation in a same session but in a seperate batch.', 18, -1 );
		END
	ELSE
		BEGIN
			EXEC sp_executesql @readerstring, N'@guid nvarchar(100) OUTPUT', @guidOut OUTPUT;

		-- Retrying for 10 seconds
		WHILE (@recommendation is null or len(@recommendation) = 0) and  DATEDIFF(second, @DelayStart, GETDATE()) < 10
		BEGIN
			EXEC sp_executesql @readrecommendation, N'@recommendation nvarchar(max) OUTPUT, @corrid nvarchar(100) OUTPUT, @guidOut nvarchar(100)', @recommendation OUTPUT, @corrid OUTPUT, @guidOut;
			if (@recommendation is null or len(@recommendation) = 0)
			BEGIN
				RAISERROR(N'No recommendation yet in ring buffer; waiting...', 0, -1);
			END
		END

		IF (@recommendation is null or len(@recommendation) = 0)
			BEGIN
				RAISERROR(N'No recommendation was found', 18, -1);
			END
		ELSE
			BEGIN
				-- parse the recommendation result
				DECLARE @FirstDistribBegin int = PATINDEX('%Table Distribution Changes%', @recommendation);
				DECLARE @FirstDistribEnd int = PATINDEX('%------------------------------------------------------------%', @recommendation);
				DECLARE @JumpPast nvarchar(max) = 'Table Distribution Changes';

				SET @FirstDistribBegin = @FirstDistribBegin + LEN(@JumpPast) + 2; -- +1 to eat newline at the beginning
				DECLARE @DistribLength int = @FirstDistribEnd - @FirstDistribBegin - 3; -- extra -2 to remove newlines at the end

				DECLARE @FirstDistrib nvarchar(max);
				SELECT @FirstDistrib = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(@recommendation, @FirstDistribBegin, @DistribLength), CHAR(9), ''), '->', ''), '  ', ' '), ' ', '","'), CHAR(10), '"],["'); 
				SELECT @FirstDistrib = REPLACE(REPLACE(@FirstDistrib, 'Distributed', 'Hash'), ':', '');
				SELECT @FirstDistrib = '[["' + @FirstDistrib + '"]]';

				-- create table 
				select TableName, CurrentDistribution, SuggestedDistribution, ChangeCommand = 
					case when CurrentDistribution = SuggestedDistribution 
					then N'<no change>' 
					else CONCAT(N'create table ', TableName, N'_changed with (distribution=', SuggestedDistribution, N', clustered columnstore index) as select * from ', TableName, N';') 
					end
				from (
					select [0] as TableName, [1] as CurrentDistribution, [2] as SuggestedDistribution
					from (
					select pvt.*
					from (select row_no = [rows].[key], col_no = [cols].[key], cols.[value]
						  from 
							(select [json] = @FirstDistrib) step1
							cross apply openjson([json]) [rows]
							cross apply openjson([rows].[value]) [cols]
						 ) base
					pivot (max (base.[value]) for base.col_no in ([0], [1], [2])) pvt
					) x
				) y
			END
		END
	

		DECLARE @DeleteTempTable nvarchar(max) = CONCAT(N'if exists (select * from sys.tables where name = ''', @TempTableName, N''') drop table ', @TempTableName);
		EXEC(@DeleteTempTable);
END
GO



IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.write_dist_recommendation'))
	DROP PROCEDURE dbo.write_dist_recommendation
go

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.read_dist_recommendation'))
	DROP PROCEDURE dbo.read_dist_recommendation
go

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.format_recommendation'))
	DROP PROCEDURE dbo.format_recommendation
go

CREATE PROCEDURE dbo.format_recommendation @recommendation NVARCHAR(MAX)
AS
BEGIN
    IF (@recommendation IS NULL OR len(@recommendation) = 0)
      BEGIN
          RAISERROR (N'No recommendation was found', 18, - 1);
      END
    ELSE
    BEGIN
        -- Parse the recommendation result
        DECLARE @FirstDistribBegin INT = PATINDEX('%Table Distribution Changes%', @recommendation);
        DECLARE @FirstDistribEnd INT = PATINDEX('%------------------------------------------------------------%', @recommendation);
        DECLARE @JumpPast NVARCHAR(max) = 'Table Distribution Changes';

		SET @FirstDistribBegin = @FirstDistribBegin + LEN(@JumpPast) + 2; -- +1 to eat newline at the beginning
		DECLARE @DistribLength int = @FirstDistribEnd - @FirstDistribBegin - 2; -- extra -2 to remove newlines at the end

        IF (@DistribLength <= 0)
          BEGIN
              RAISERROR (N'No distribution to show. The query does not involve any tables, or the tables do not exist.', 18, - 1);
          END
        ELSE
            DECLARE @FirstDistrib NVARCHAR(max);

        SELECT @FirstDistrib = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(@recommendation, @FirstDistribBegin, @DistribLength), CHAR(9), ''), CHAR(13), ''), '->', ''), '  ', ' '), ' ', '","'), CHAR(10), '"],["');

        SELECT @FirstDistrib = REPLACE(REPLACE(@FirstDistrib, 'Distributed', 'Hash'), ':', '');

        SELECT @FirstDistrib = '[["' + @FirstDistrib + '"]]';

        -- Format the recommendation output 
        SELECT y.TableName
            , CurrentDistribution
            , SuggestedDistribution
            , ChangeCommand = CASE 
                WHEN CurrentDistribution = SuggestedDistribution
                    THEN N'<no change>'
                ELSE CONCAT (
                        N'CREATE TABLE ', y.TableName, N'_changed 
                        WITH (DISTRIBUTION=', REPLACE(REPLACE(SuggestedDistribution, 'replicated', 'REPLICATE'), 'Hash', 'HASH'), N', ', i.TableIndex, ') 
                        AS SELECT * FROM ', y.TableName, N';

                        DROP TABLE ', y.TableName, '; 
                        RENAME OBJECT ', y.TableName, N'_changed TO ', i.tableName, ';')
                END
            , Remarks = CASE 
                WHEN PATINDEX('%Hash%', CurrentDistribution) > 0
                    AND CHARINDEX(',', CurrentDistribution) > 0
                    THEN N'MCD tables are not considered by the current DA version.'
                ELSE ''
                END
        FROM (
            SELECT [0] AS TableName
                , [1] AS CurrentDistribution
                , [2] AS SuggestedDistribution
            FROM (
                SELECT pvt.*
                FROM (
                    SELECT row_no = [rows].[key]
                        , col_no = [cols].[key]
                        , cols.[value]
                    FROM (
                        SELECT [json] = @FirstDistrib
                        ) step1
                    CROSS APPLY openjson([json]) [rows]
                    CROSS APPLY openjson([rows].[value]) [cols]
                    ) base
                pivot(max(base.[value]) FOR base.col_no IN ([0], [1], [2])) pvt
                ) x
            WHERE [1] IS NOT NULL
                AND [2] IS NOT NULL
            ) y
        JOIN (
            SELECT CONCAT (
                    DB_NAME()
                    , '.'
                    , OBJECT_SCHEMA_NAME(t.object_id)
                    , '.'
                    , t.name
                    ) AS FullObjectName
                , OBJECT_SCHEMA_NAME(t.object_id) AS schemaName
                , t.name AS tableName
                , i.type
                , CASE i.type
                    WHEN 0
                        THEN 'HEAP'
                    WHEN 1
                        THEN CONCAT ('CLUSTERED INDEX (', STRING_AGG(c.Name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal ASC), ')')
                    WHEN 5
                        THEN 'CLUSTERED COLUMNSTORE INDEX'
                    END AS TableIndex
            FROM sys.tables t
            LEFT JOIN sys.indexes i
                ON t.object_id = i.object_id
                    AND i.type IN (0, 1, 5)
            LEFT JOIN sys.index_columns ic
                ON i.index_id = ic.index_id
                    AND i.object_id = ic.object_id
            LEFT JOIN sys.columns c
                ON ic.column_id = c.column_id
                    AND ic.object_id = c.object_id
            GROUP BY t.name
                , t.object_id
                , i.name
                , i.type
            ) i
            ON y.TableName = i.FullObjectName
    END
END
GO

CREATE PROCEDURE write_dist_recommendation
	@NumMaxQueries int, 
	@Queries NVARCHAR(MAX)
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	DECLARE @sessionid nvarchar(max) = SESSION_ID();
	DECLARE @guid nvarchar(100) = REPLACE(NEWID(), '-', '');
	DECLARE @guidpusher nvarchar(max) = CONCAT(N'    --distrib_advisor_correlation_id_', @guid, CHAR(13), CHAR(10));
	DECLARE @recostring nvarchar(max);
	if not exists ( select * from sys.tables where name = 'DistributionAdvisorSelectedQueries')
		create table DistributionAdvisorSelectedQueries(command nvarchar(4000), tot_te bigint) with(clustered columnstore index, distribution = ROUND_ROBIN);

	-- Filter queries that will not be considered by DA.
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
	EXEC sp_executesql @sql, N'@recostring nvarchar(max) OUTPUT, @guidpusher nvarchar(max), @nmq int, @customQueries nvarchar(max)', @recostring OUTPUT, @guidpusher, @NumMaxQueries, @Queries;

	IF (@recostring is null or len(@recostring) = 0)
	BEGIN
		RAISERROR(N'Cannot construct the set of queries to feed to advisor. This often happens if there are not enough queries in sys.dm_pdw_exec_requests.', 18, -1);
	END
	ELSE
		BEGIN
			-- For debugging purposes.
			SELECT @recostring AS Command_To_Invoke_Distribution_Advisor;

			-- A command to invoke Distribution Advisor with the above string.
			EXEC sp_executesql @recostring;

			RAISERROR(N'Please use ''read_dist_recommendation'' stored procedure after recommendation is created to retrieve it', 0, -1);
		END
END
GO

-- This stored procedure reads the recommendation advice generated in write_dist_recommendation.
CREATE PROCEDURE read_dist_recommendation
AS BEGIN

	DECLARE @sessionid nvarchar(max) = SESSION_ID();

	-- get the answer from ring buffer; we may have to wait a bit, so we do a few tries for the ring buffer to get ready
	DECLARE @recommendation nvarchar(max);
	DECLARE @readrecommendation nvarchar(max) = N'select @recommendation = recommendation from sys.dm_pdw_distrib_advisor_results where @sessionid = session_id ';
	DECLARE @DelayStart datetime = GETDATE();

	-- Retrying for 10 seconds
	WHILE (@recommendation is null or len(@recommendation) = 0) and  DATEDIFF(second, @DelayStart, GETDATE()) < 10
	BEGIN
		EXEC sp_executesql @readrecommendation, N'@recommendation nvarchar(max) OUTPUT, @sessionid nvarchar(max)', @recommendation OUTPUT, @sessionid;
		if (@recommendation is null or len(@recommendation) = 0)
		BEGIN
			RAISERROR(N'No recommendation yet in ring buffer; waiting...', 0, -1);
		END
	END

	-- parsing and formatting the recommendation
	EXEC dbo.format_recommendation @recommendation;
END
GO

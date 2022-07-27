/*
IF OBJECT_ID('mpmtest') IS NOT NULL
  BEGIN;
	DROP TABLE mpmtest
END

declare @path varchar(400), @dt datetime2, @credential varchar(500),@outputable varchar(500),@display int, @debug int;
set @path = 'https://storageaccount.blob.core.windows.net/container/delta/demo/'
--set @dt =  convert(datetime2,'2022/07/06 18:37:00'); --getdate(); --  for time travel -- 
set @dt =  getdate(); --  for time travel -- 
set @credential  = 'IDENTITY= ''Shared Access Signature'', SECRET = ''___SECRET____''';
set @outputable = 'mpmtest' -- leave empty for temp table
set @display = 1; -- if 1 display results
set @debug = 1;
exec delta @path,@dt,@credential,@outputable,@display, @debug

--select count(*) from mpmtest;
*/



create PROC [dbo].[delta] 
	@folder [varchar](4000), 
	@dt [datetime2], 
	@credential [varchar](4000), 
	@dest_table [varchar](4000),
	@display int, -- 0 dont display, 1 display
	@debug int -- 0 dont debug , 1 debug mode
	AS
begin
-- version info
-- 0.1 - Very basic, but sort of worked.
-- 0.2 - Added support for remove files.
-- 0.3 - Fixed bug , in authenication
-- 0.4 - Improved performance in handling add/remove files
-- 0.5 - Added support for checkpoint files
-- 0.6 - Changed the json handling, added latest checkpoint handing

	DECLARE @ts bigint,@tsmil bigint, @json varchar(8000), @tsql varchar(8000);
	DECLARE @json_remove varchar(8000), @tsql_checkpoint varchar(8000);
	DECLARE @td_checkpoint1 datetime2, @td_checkpoint2 datetime2;
	DECLARE @last_checkpoint varchar(25), @jsonversionchar varchar(25),@checkpointversion varchar(25) ;
	DECLARE @output_sql varchar(max);
	DECLARE @checkpoint_file_count bigint;

	-- default: AAD authenication
    IF (@credential IS NULL)
        SET @credential = ''

    IF (@credential <> '')
        SET @credential = ' CREDENTIAL = (' + @credential + ')'

	-- default : display results
	IF @display IS NULL
		set @display = 1

	-- default : debug is off
	IF @debug IS NULL 
		SET @debug = 0
	
	-- if the datetime is null, get the latest version
	IF (@dt IS NULL)
		set @dt = getdate()

	-- number of milliseconds since 1970
	-- Datediff doesn't return a bigint - so I need todo this into 2 parts
	set @ts  = datediff( s, '1970/1/1', convert(date,@dt) ) 
	set @ts = @ts * 1000;

	set @tsmil = datediff(ms, convert(date,@dt) , @dt)
	set @ts = @ts + @tsmil;

	if (@dest_table IS NULL)
		set @dest_table = '#tmp_output'

	---- Holds the raw json information -----------------------------
	IF OBJECT_ID('tempdb..#last_checkpoint') IS NOT NULL
		DROP TABLE #last_checkpoint

	create table #last_checkpoint
	(
		info varchar(max)
	) with (distribution=round_robin, heap)

	------ read _last_checkpoint
	-- This gives us the checkpoint if it exists, this gives us the starting point
	-- for the json files
	set @tsql = '
	copy into  #last_checkpoint (info)
	from ''' + @folder + '_delta_log/_last_checkpoint''
	 with ( 	' + @credential +  '    ,FILE_TYPE = ''CSV''
	 ,fieldterminator =''0x0b''    ,fieldquote = ''0x0b''     ,rowterminator = ''0x0d'' ) '
 
	if @debug = 1 	
		print @tsql;
 
	set @td_checkpoint1 = getdate();  
	exec(@tsql);
	set @td_checkpoint2 = getdate();

	print 'Loading _last_checkpoint files took ' + convert(varchar(50),datediff(ms, @td_checkpoint1,@td_checkpoint2)) + ' ms'

	if @debug = 1 
	begin 
		select '_Last_checkpoint', *  from #last_checkpoint
	end
	
	select @checkpointversion = ISNULL(JSON_VALUE(info,'$.version'),'00') from #last_checkpoint;
	
	if NOT EXISTS(SELECT * FROM #last_checkpoint)
	BEGIN
		SET @checkpointversion = '00'
	END


	PRINT 'checkpointversion=' +@checkpointversion

	set @jsonversionchar = '00000000000000000000';

	IF OBJECT_ID('tempdb..#delta_checkpoint') IS NOT NULL
		DROP TABLE #delta_checkpoint

	create table #delta_checkpoint
	(
		txn varchar(max),
		[add] varchar(max),
		[remove] varchar(max),
		metaData varchar(max),
		protocol varchar(max)
	) with (distribution=round_robin, heap)

	--- Code to pull the the add / remove files from the checkpoint files.
	set @tsql_checkpoint = ' 
	copy into  #delta_checkpoint	from ''' + @folder + '_delta_log/*.checkpoint.parquet''
	 with ( ' + @credential +  '  ,FILE_TYPE = ''PARQUET'', AUTO_CREATE_TABLE = ''ON''   ) '

	 if @debug = 1
	 BEGIN
		print @tsql_checkpoint;
	END
 
	set @td_checkpoint1 = getdate()  
	exec(@tsql_checkpoint);
	set @td_checkpoint2 = getdate()

	print 'Loading checkpoint files took ' + convert(varchar(50),datediff(ms, @td_checkpoint1,@td_checkpoint2)) + ' ms'

	SELECT @checkpoint_file_count = count(*) from #delta_checkpoint

	 if @debug = 1 
	 BEGIN
		print 'No of checkpoint files ' + convert(varchar(10),@checkpoint_file_count);
		
		SELECT * FROM #delta_checkpoint order by [add],[remove]
	END
	-- Holds the information from the checkpoint files ---------
	IF OBJECT_ID('tempdb..#delta_files_checkpoint') IS NOT NULL
	  BEGIN;
		print 'Dropping table #delta_files_checkpoint'
		DROP TABLE #delta_files_checkpoint
	END
	
	create table #delta_files_checkpoint
	(
		fname varchar(99),
		ts bigint,
		dt datetime2,
		[action] char(1)
	) with (distribution=round_robin, heap)

	-- create a table of add/remove files with the datetimestamp
	INSERT INTO #delta_files_checkpoint
	select DISTINCT
		CASE WHEN JSON_VALUE([add],'$.path') is NULL THEN
			JSON_VALUE([remove],'$.path')
		ELSE
			JSON_VALUE([add],'$.path') 
		END fname,
		CASE 
		WHEN JSON_VALUE([add],'$.path') is NULL THEN
			convert(bigint,JSON_VALUE([remove],'$.deletionTimestamp'))
		ELSE
			convert(bigint,JSON_VALUE([add],'$.modificationTime')) 
			END updatetime,
		CASE 
		WHEN JSON_VALUE([add],'$.path') is NULL THEN
			dateadd(s, convert(bigint,JSON_VALUE([remove],'$.deletionTimestamp'))  / 1000 , '1970/1/1')
		ELSE
			dateadd(s, convert(bigint,JSON_VALUE([add],'$.modificationTime'))  / 1000 , '1970/1/1')
		END updatetimedt,
		CASE	WHEN JSON_VALUE([add],'$.path') is NULL THEN
			'R'
		ELSE
			'A'
		END [action]
		from #delta_checkpoint

	DELETE from #delta_files_checkpoint where fname is null

	if @debug = 1 	
		SELECT 'checkpoint', * , @ts, @dt FROM #delta_files_checkpoint order by dt desc

	 -- remove files after the given time 
	 DELETE FROM #delta_files_checkpoint  	WHERE ts > @ts 

	if @debug = 1 	
		SELECT 'checkpoint filtered', * , @ts, @dt FROM #delta_files_checkpoint  order by dt desc

	---- Holds the raw json information -----------------------------
	IF OBJECT_ID('tempdb..#delta_json') IS NOT NULL
	  BEGIN;
		DROP TABLE #delta_json
	END

	create table #delta_json
	(
		jsoninput varchar(max)
	) with (distribution=round_robin, heap)
	----------------------------------------------------------------

	set @jsonversionchar=  left(substring(@jsonversionchar,0,len(@jsonversionchar)-len(@checkpointversion)+1) + @checkpointversion,len(@jsonversionchar)-1) + '*'

	-- Read all the delta transaction logs, we cant filter out things by file name.
	set @tsql = '
	copy into  #delta_json (jsoninput)
	from ''' + @folder + '_delta_log/'+ @jsonversionchar +'.json''
	 with ( 	' + @credential +  '    ,FILE_TYPE = ''CSV''
	 ,fieldterminator =''0x0b''    ,fieldquote = ''0x0b''     ,rowterminator = ''0x0d'' ) '
 
	if @debug = 1 	
		print @tsql;
 
	set @td_checkpoint1 = getdate();  
	exec(@tsql);
	set @td_checkpoint2 = getdate();

	print 'Loading json files took ' + convert(varchar(50),datediff(ms, @td_checkpoint1,@td_checkpoint2)) + ' ms'

	if @debug = 1 	
		SELECT 'JSON Files', * , @ts, @dt FROM #delta_json

	---- delta file details..
	IF OBJECT_ID('tempdb..#delta_active_json') IS NOT NULL
	  BEGIN;
		DROP TABLE #delta_active_json
	END

	create table #delta_active_json
	(
		jsoninput varchar(max) , 
		ts bigint,
		dt datetime2,
		[action] char(1)
	) with (distribution=round_robin, heap)
	-----------------------------------------------------------

	-- inserting into temp table, so the date and time is associated to each row
	insert into #delta_active_json
		select  
			convert(varchar(max),jsoninput)
			, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  as ts
			, dateadd(s, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  / 1000 , '1970/1/1')
			,''
		from #delta_json 
		WHERE convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp')) < @ts  


	if @debug = 1 	
		select 'json filtered by date',*, @ts, @dt	from #delta_active_json order by dt desc

	-- left in for debugging -- shows each version of the JSON
	if @debug = 1 
	begin
		select  'not filtered',
		convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  as ts
		, convert(varchar(8000),jsoninput)
		, dateadd(s, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  / 1000 , '1970/1/1')
		,ROW_NUMBER() OVER(PARTITION BY NULL ORDER BY  JSON_VALUE(jsoninput,'$.commitInfo.timestamp') DESC) AS "Row Number" 
		,convert(varchar(8000),jsoninput)
		, @ts, @dt 
		from #delta_json  
		order by convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  desc
	end


	---------------------------------------------------------
	-- insert the JSON adds and removes to the existing list from checkpoint
	insert into #delta_files_checkpoint
	select  substring(value,charindex('path',value)+7 ,67) [path] 
			, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp')) ts
			, dateadd(s, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  / 1000 , '1970/1/1') td
			,'A' as [action]
	from #delta_active_json 
		cross apply STRING_SPLIT(jsoninput,',') 
	where value like '%path%' and  charindex('add',value) > 0
	union all
	select   substring(value,charindex('path',value)+7 ,67)
			, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp')) ts
			, dateadd(s, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  / 1000 , '1970/1/1') td
			, 'R'
	from #delta_active_json 
		cross apply STRING_SPLIT(jsoninput,',') 
	where value like '%path%' and  charindex('remove',value) > 0


	if @debug = 1 
	begin
		-- all the adds and removes from the json
		select 'adds', substring(value,charindex('path',value)+7 ,67) [path] 
			, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp')) ts
			, dateadd(s, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  / 1000 , '1970/1/1') td
			,'A' as [action] , @ts, @dt
		from #delta_active_json 
			cross apply STRING_SPLIT(jsoninput,',') 
		where value like '%path%' and  charindex('add',value) > 0

		select  'removes',  substring(value,charindex('path',value)+7 ,67)
				, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp')) ts
				, dateadd(s, convert(bigint,JSON_VALUE(jsoninput,'$.commitInfo.timestamp'))  / 1000 , '1970/1/1') td
				, 'R', @ts, @dt
		from #delta_active_json 
			cross apply STRING_SPLIT(jsoninput,',') 
		where value like '%path%' and  charindex('remove',value) > 0
	
		select 'New list with adds and removes', *, @ts, @dt from #delta_files_checkpoint order by ts desc;
	
		select distinct 'distinct list ', fname, dt, [action], @ts, @dt  from #delta_files_checkpoint order by dt desc;
	end


	---- Holds the raw json information -----------------------------
	IF OBJECT_ID('tempdb..#delta_files') IS NOT NULL
	  BEGIN;
		DROP TABLE #delta_files
	END

	create table #delta_files
	(
		filenames varchar(max), rownumber bigint
	) with (distribution=round_robin, heap)

	insert into #delta_files
		select fname, 
		ROW_NUMBER() OVER(PARTITION BY NULL ORDER BY fname DESC) 
		from #delta_files_checkpoint where [action] = 'A' and
			fname not in (select fname from  #delta_files_checkpoint where [action] = 'R') 

	if @debug = 1 
		select '#delta_files', * from #delta_files;

	if @debug = 1 
		select 'parquet to read ', fname,ts, @ts, dt, @dt from #delta_files_checkpoint where [action] = 'A' and
			fname not in (select fname from  #delta_files_checkpoint where [action] = 'R') 
		--where ts < @ts

	--- This batching code might appear over kill, but STRING_AGG falls over when the string
	-- is too long.. so I am batching up the inserts.

	DECLARE @flist varchar(max);
	DECLARE @batchsize int = 100000;
	DECLARE @iParquetFileCount int =0;
	DECLARE @iParquetFilePos int =1;
	select @iParquetFileCount = count(*) from #delta_files

	IF OBJECT_ID('tempdb..#_files') IS NOT NULL
		DROP TABLE #_files

	create table #_files
	( fname varchar(999) ) with (distribution=round_robin,heap)

	---- creating batches of COPY INTO statements
	while(@iParquetFilePos <= @iParquetFileCount)
	BEGIN
		INSERT INTO #_files 
		SELECT [filenames] FROM #delta_files where rownumber between @iParquetFilePos and @iParquetFilePos + @batchsize 

		-- Had issues with STRING_AGG with if the string gets too long
		SELECT @flist = 'COPY INTO  ' + @dest_table + '  FROM '  
						+ STRING_AGG(CAST(''''+@folder+fname+'''' AS VARCHAR(MAX)), ',
						') + '   with ( 	' + @credential +  '
							,FILE_TYPE = ''PARQUET''  , AUTO_CREATE_TABLE = ''ON''  )' 
							FROM #_files

		if @debug =1 
			select '_filelist', * from #_files;
		
		if @debug =1 print @flist;
		if @debug =1 print len(@flist);

		set @td_checkpoint1 = getdate();  
		exec(@flist);
		set @td_checkpoint2 = getdate();

		print 'Loading batch of parquet ' + convert(varchar(10),@iParquetFilePos) + '->' +  convert(varchar(10), @iParquetFilePos + @batchsize ) + ' took ' + convert(varchar(50),datediff(ms, @td_checkpoint1,@td_checkpoint2)) + ' ms'

		truncate table #_files;
		set @iParquetFilePos = @iParquetFilePos + @batchsize +1;
	END
	
	-- if there is no file, there is no table and this causes a problem
	if charindex('#',@dest_table) > 0
		set @output_sql = 'IF OBJECT_ID(''tempdb..' + @dest_table + ''') IS NOT NULL 	 SELECT * from ' + @dest_table + ';'
	ELSE
		set @output_sql = 'IF OBJECT_ID(''' + @dest_table + ''') IS NOT NULL 	 SELECT * from ' + @dest_table + ';'

	if @debug = 1
		PRINT @output_sql;
	
	if @display = 1
		exec(@output_sql );

end
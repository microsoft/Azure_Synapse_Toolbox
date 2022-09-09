
-- *******************************************************************************************
-- This portion is for a user input queries. 
-- PDW doesn't allow default values for stored procedures. So the input queries needs to be single string divided by a semicolon between each queries.
-- This can be simply done by declaring a variable for each query string, and then combine them by using CONCAT() function.
-- Max query number parameter is ignored in this scenario.
EXEC dbo.write_dist_recommendation NULL, 'select count (*) from t1; select * from t1 join t2 on t1.a1 = t2.a1; select count (*) from t1; select * from t1 join t2 on t1.a1 = t2.a1;';
go
-- Notice that the read_dist_recommendation and write_dist_recommendation stored procs need to be called together and seperated by go.
EXEC dbo.read_dist_recommendation;
go

-- *******************************************************************************************
-- This portion is for running DA on top @MaxNumQueries queries.
-- @MaxNumQueries parameter value can be in [1...100] range.
-- if both parameters passed as NULL, the stored procedure will generate recommendation for top 100 queries.
EXEC dbo.write_dist_recommendation 100, NULL
go
EXEC dbo.read_dist_recommendation;
go

-- *******************************************************************************************
-- The below is an example usage of format_recommendation stored procedure.
-- It takes the recommendation result as a parameter and displays in a formatted readable manner.
set recommendations on;
go

select 1;

set recommendations off;
go

DECLARE @sessionid nvarchar(100);
DECLARE @recommendation nvarchar(MAX);
select @sessionid = SESSION_ID();
select @recommendation = recommendation from sys.dm_pdw_distrib_advisor_results where session_id = @sessionid
EXEC dbo.format_recommendation @recommendation;
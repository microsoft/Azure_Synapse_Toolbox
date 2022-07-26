/*
	==========================
	   Identify Blocking 1
	==========================
	This query looks for any queries that are not currently granted, then returns all other waits on that same object. 
    Returns no results if there are no blocked queries. 
    
    Example: if there is a queued query waiting on an exclusive lock on an object, any other lock on that object that 
    is currently granted is considered blocking that query.   
*/
select * from sys.dm_pdw_waits
where object_name in (select object_name from sys.dm_pdw_waits where state != 'Granted')
order by object_name
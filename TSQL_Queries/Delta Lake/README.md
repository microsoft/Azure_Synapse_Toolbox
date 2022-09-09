# Reading Delta Lake

    This stored procedure reads Delta Lake, it supports time travel but does not support schema drift.

    This is a breakdown of how the script works.

    - Read the _last_checkpoint file, this contains the highest checkpoint version number.
    - Read all the checkpoint files, these contain the 'Add' and 'Remove' files that need to be included and their timestamps.
    - Read the latest JSON transaction files (since the last checkpoint), these contain the most recent 'Add' and 'Remove' files that need to be included and their timestamps.
    - Filter out the 'Add' and 'Remove' files based on the 'modificationTime' and 'deletionTimestamp'
    - Return the data from all the 'Add' files excluding the 'Remove' files. (Batching up the COPY INTO statements)
    
## Installation

Run Delta.sql to create the stored procedures in dbo.

## Using the Procedure

    Run the delta.sql script, this creates the delta stored procedure.

### Parameters
```
    @Folder -> String. The location of the Delta Lake file, including HTTPS
    @DT -> Datetime2. Gives us the version of the file at this time. (NULL returns latest version)
    @Credential -> String.  Full credential string (NULL defaults to AAD authentication)
    @Destination Table -> String.  Destination table for loading the files. (NULL means a temp table is used)
    @Display -> Int. 0  = Don't display results,  1 = Display results.
    @Debug -> Int.  0 = Hide debug information.  1 = Show debug information.
```

### Example

``` sql
declare @path varchar(400), @dt datetime2, @credential varchar(500),@outputable varchar(500),@display int, @debug int;

set @path = 'https://storageaccount.blob.core.windows.net/container/delta/demo/'
--set @dt =  convert(datetime2,'2022/07/06 18:37:00');  --  for time travel 
set @dt =  getdate(); --  for time travel -- 
set @credential  = 'IDENTITY= ''Shared Access Signature'', SECRET = ''___SECRET____''';
set @outputable = 'mpmtest' -- leave empty for temp table
set @display = 1; -- if 1 display results
set @debug = 1; -- if 1 display debugging information
exec delta @path,@dt,@credential,@outputable,@display, @debug

```


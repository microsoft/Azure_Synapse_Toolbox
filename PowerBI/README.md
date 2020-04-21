# This template is a work in progress and is not yet meant for use in production

This template is a work in progress, but is in a usable state. It currently only has realtime pages from querying DMVs. It will  get historical data as well as I post updates. 

# Variables

When you open the template it will as you to fill in a number of variables. A lot of these are for future use or will be removed later. 

**SQLDW_Servername:** the name of the server your SQLDW resides on in the form sqldwname.database.windows.net

**DatbaseName:** The name of your SQLDW Database

**LogAnalyticsWorkspaceID:** Not in use, enter any text value

**StorageAccountName:** Not in use, enter any text value

**RangeStart:** Not in use, enter any date value in the form 4/21/2020 1:00:00 AM

**RangeEnd:** Not in use, enter any date value in the form 4/21/2020 1:00:00 AM

**SQLDW_Servername_short:** Not in use, enter any text value

# Pre-Requisites

There are currently no pre-requisites otehr than a running SQLDW Instance. In future releases there will be Log Analytics queries and the below pre-requisites will apply to that. 

Create a Log analytics workspace - save the WorkspaceID

On your SQLDW Instance, go to 'diagnostic settings' and create a new setting to send all diagnostics to your log analytics workspace. For now, you can leave out DMS_Workers and SQL Requests. These are very large and incur a high cost, so I am leaving them out for now. 

# Messages about Native Database Queries

Most of the DMVs are collected using native datbase queries. You need to allow each one permissions to run by hitting 'Run' on the popup.  

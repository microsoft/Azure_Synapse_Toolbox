# This template is a work in progress
Realize that there may still be some inaccurate data in some of the queries. If this is used in a production environment it should be done so with this understanding. Especially when it comes to the "Query Activity" tab, which uses SQL Audit data. Results could be inconsistent. 

## Pre-Requisites
1. Log Analytics workspace created
2. Diagnostic settings enabled to send all diagnostics except DMS Workers and SQL Requests to log analytics
3. Auditing enabled for the database or server and sent to Log Analytics (without this there should just be 1 tab that will be broken)

## To use the template:
1. Create a new workbook in Azure Monitor
2. Click edit if you are not already in edit mode
3. Click the advanced editor button
4. Paste in the contents of this JSON into the Gallery Template and Save

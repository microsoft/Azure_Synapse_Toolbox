# This template is a work in progress
Realize that there may still be some inaccurate data in some of the queries. If this is used in a production environment it should be done so with this understanding. Especially when it comes to the "Query Activity" tab, which uses SQL Audit data. Results could be inconsistent. 

## Pre-Requisites
1. Log Analytics workspace created
2. Diagnostic settings enabled to send all diagnostics except DMS Workers and SQL Requests to log analytics
3. Auditing enabled for the database or server and sent to Log Analytics (without this the 'Query Activity' tab will not have any data)

## To use the template:
1. Create a new workbook in Azure Monitor (accessing directly from Azure Workbooks does not have a 'new workbook' button)
2. Click edit if you are not already in edit mode
3. Click the advanced editor button - "</>"
4. Paste in the contents of this JSON into the Gallery Template and Save
5. Fill in the radio parameters at the top to populate your dashboards.

## To configure additional components to be monitored: 

Spark Pools: Follow these instructions to configure diagnostic settings and download the workbook https://user-images.githubusercontent.com/14915318/126400447-5993f7e1-5f62-4161-8807-c6f8e195c920.png

Storage accounts: When creating a workbook, search public templates for storage account and you will see storage account workbooks

Pipeline/trigger runs: Workbook in progress, data sent to log analytics through workspace diagnostic settings

Serverless: Wokrbook in progress, data sent to log analytics through workspace diagnostic settings

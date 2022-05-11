# Monitor Synpase
Use this template to monitor your dedicated SQL Pools. 
If you have an instance that was created withint a Synapse workspace, then you will use the workspaces sql pool template. 
If the instance was deployed standalone and was not originally part of a workspace, you will use the standalone template.
![DedicatedPoolWB1](/Collateral/Screenshots/DedicatedPoolWB1.png)

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

# To configure additional components to be monitored: 

## Spark Pools
Follow these instructions to configure diagnostic settings and download the workbook https://docs.microsoft.com/en-us/azure/synapse-analytics/spark/apache-spark-azure-log-analytics
![SparkWB1](/Collateral/Screenshots/SparkWB1.png)

## Storage accounts
When creating a workbook, search public templates for storage account and you will see storage account workbooks. You can filter it just to be the storage accounts for your synapse instance or look at all at once. Clicking one of the storage accounts will take you to a separate workbook just for investigating that storage account. 
![StorageWB1](/Collateral/Screenshots/StorageAccountOverviewScreenshot_WB2.png)

## Pipeline/trigger runs
The pipeline workbook is an adaptation of an existing Azure Data Factory and serves both services. 
![PipelineWB1](/Collateral/Screenshots/SynapsePipelineWorkbook1.png)

## Serverless
Early version of the serverless workbook has been posted. This includes query execution information including costing. You must have 'diagnostic settings' enabled at the workspace level to send 'BuiltinSqlReqsEnded' to Log Analytics. 
![ServerlessWB1](/Collateral/Screenshots/ServerlessWB2.png)

# Azure Synapse Inventory via Azure Resource Graph
The following [Azure Resource Graph](https://azure.microsoft.com/en-us/features/resource-graph/) queries assist with gathering Azure tenant inventory for Azure resources related to Azure Synapse Analytics. They are intended to aid cost optimization, general inventory needs, normalizing or standardization of configuration, and more.

## Pre-Requisites
1. RBAC 'Reader' or equivalent access to Azure Synapse related resources. See [Azure Resource Graph permissions](https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview#permissions-in-azure-resource-graph) documentation for specifics.
2. Access to the Azure Portal or an Azure PowerShell or CLI session. 


## To use these queries:
1. Navigate to the Azure Portal. Search or select the [Azure Resource Graph Explorer](https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-portal) and paste the text of the desired query into the query window. Select run query.
2. Alternatively you may programmatically execute these queries programmatically via CLI or SDKs.
    - Execute Azure Resource Graph queries via [Azure PowerShell](https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-powershell)
    - Execute Azure Resource Graph queries via [Azure CLI](https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-azurecli)
    - Execute Azure Resource Graph queries via language specific [SDK or REST API](https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-rest-api) 

# Sample queries for gathering inventory: 

## Dedicated SQL Pools
[Inventory-DedicatedSqlPool](Inventory-DedicatedSqlPool.kql) - Lists dedicated SQL pools (formerly SQL DW) visible to the executing Azure context returning the subscription, resource group, parent Azure SQL Server, current SKU, standalone or association with Azure Synapse Workspace, and more.

## Serverless SQL Pools
To be completed.

## Spark Pools
[Inventory-SparkPools](Inventory-SparkPools.kql) - Lists Spark pools (Synapse Spark) visible to the executing Azure context returning the subscription, resource group, parent Azure Synapse Analytics workspace, SKU, and more. 

## Kusto Pools
To be completed.

# Troubleshooting

## Runtime errors with Azure Resource Graph

[Checklist to review](https://docs.microsoft.com/en-us/azure/governance/resource-graph/troubleshoot/general) if errors are returned or no data is returned from these queries. If not data is returned the root cause is RBAC access to the Azure Synapse related Azure resources.




//List all queries 
AzureDiagnostics
| where Category  == "ExecRequests"
| project TimeGenerated , ErrorId_g , RequestId_s , SessionId_s , Status_s , SubmitTime_t , StartTime_t , EndCompileTime_t , EndTime_t , Label_s , DatabaseId_d , Command_s , ResourceClass_s , StatementType_s

//Chart the most active resource classes
AzureDiagnostics
| where Category contains "ExecRequests"
| where Status_s == "Completed"
| summarize totalQueries = dcount(RequestId_s) by ResourceClass_s
| render barchart

//Count of all queued queries
AzureDiagnostics
| where Category contains "waits" 
| where Type_s == "UserConcurrencyResourceType"
| summarize totalQueuedQueries = dcount(RequestId_s)

//Longest Running Query Steps
AzureDiagnostics
| where Category == "RequestSteps"
| where OperationType_s in ("ShuffleMoveOperation", "BroadcastMoveOperation", "PartitionMoveOperation", "RoundRobinMoveOperation", "SingleSourceRoundRobinMoveOperation", "MoveOperation", "TrimMoveOperation")
| where Status_s == "Complete"
| project RequestId_s, OperationType_s, duration_ms=datetime_diff('millisecond',EndTime_t, StartTime_t), RowCount_d , TimeGenerated  
| order by duration_ms desc

//Request Steps
AzureDiagnostics
| where Category  == "RequestSteps"
| project TimeGenerated , ErrorId_g , OperationType_s , DistributionType_s , LocationType_s , StepIndex_d , RowCount_d , RequestId_s , Status_s , StartTime_t  , EndTime_t , Command_s 

//SQL Requests
AzureDiagnostics
| where Category  == "SqlRequests"
| project TimeGenerated , StepIndex_d , PdwNodeId_d , DistributionId_d , RowCount_d , Spid_d ,  RequestId_s , Status_s , StartTime_t , EndTime_t , Command_s 

//Blocked By Firewall
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="blocked_by_firewall"
| project MetricName , Maximum, TimeGenerated 

//Cache Hit Percent
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="cache_hit_percent"
| project MetricName , Maximum, TimeGenerated 

//Connection Failed
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="connection_failed"
| project MetricName , Maximum, TimeGenerated  

//Connection Success
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="connection_successful"
| project MetricName , Maximum, TimeGenerated  

//CPU Percent
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="cpu_percent"
| project MetricName , Maximum, TimeGenerated

//DWU Consumption Percent
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="dwu_consumption_percent"

//Tempdb ConsumptionPercent
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="local_tempdb_usage_percent"
| project MetricName , Maximum, TimeGenerated

//Memory Usage Percent
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="memory_usage_percent"
| project MetricName , Maximum, TimeGenerated

//Physical Data Read Percent
AzureMetrics 
| where ResourceProvider  == "MICROSOFT.SQL"
| where Resource == "NICKSALCSQLDW1"
| where MetricName =="physical_data_read_percent"
| project MetricName , Maximum, TimeGenerated

//Current DWU
AzureMetrics | where MetricName == 'dwu_limit' 
| where Resource == 'NICKSALCSQLDW1'
| project TimeGenerated , MetricName , Maximum 
| sort by TimeGenerated  
| limit 1
| project MetricName , Maximum, TimeGenerated
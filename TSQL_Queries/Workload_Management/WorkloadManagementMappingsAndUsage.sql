--Mapping details + effective grants + specified grants
SELECT * FROM 
(SELECT 
    wc.name AS 'ClassifierName'
    ,wc.group_name AS 'GroupName'
    ,wc.importance AS 'ClassifierImportance'
    ,wg.importance AS 'GroupImportance'
    ,wcd.classifier_type
    ,wcd.classifier_value
    ,wg.min_percentage_resource
    ,wgs.effective_min_percentage_resource
    ,wg.cap_percentage_resource
    ,wgs.effective_cap_percentage_resource
    ,wg.request_min_resource_grant_percent
    ,wgs.effective_request_min_resource_grant_percent
    ,wg.request_max_resource_grant_percent
    ,wgs.effective_request_max_resource_grant_percent
    ,wgs.total_request_count
    ,wgs.total_shared_resource_requests
    ,wgs.total_queued_request_count
    ,wgs.total_request_execution_timeouts
    ,wgs.total_resource_grant_timeouts
FROM sys.workload_management_workload_classifiers wc
JOIN sys.workload_management_workload_classifier_details wcd
ON wc.classifier_id = wcd.classifier_id
JOIN sys.dm_workload_management_workload_groups_stats wgs
ON wgs.name = wc.group_name
JOIN sys.workload_management_workload_groups wg
ON wg.group_id = wgs.group_id
) AS Source
PIVOT (max(Classifier_Value) FOR Classifier_Type in ([membername],[wlm_label],[wlm_context],[start_time],[end_time])) AS PivotTable


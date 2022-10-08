# Synpase Toolkit

	The Synapse Toolkit is a set of stored procedures that help investigate
	current activity on your Synapse Dedicated SQL Pool. sp_status is the overall
	summary procedure that calls various other procedures to provide a picture
	of current activity. Use the detail_command columns to deep dive into a 
	particular session, query, or wait. 
	
	List of SPs currently included:
		sp_status
		sp_concurrency
		sp_requests
		sp_reqeusts_detail
		sp_sessions
		sp_sessions_detail
		sp_waits
		sp_waits_detail
		sp_datamovement

- BETA Version includes new fields in the 'running queries' output to show cpu, IO, and cost metrics. These metrics are being tested for accuracy. 
    
## Installation

Run SynpaseToolkit.sql to create the stored procedures in dbo. If stored procedures with this name already exist they will overwrite them. 

## Using the Toolkit

Run **EXEC sp_status** to get an overview of system activity. Then use the comands provided in the last column(s) to dive deeper.

For the best experience execute with SSMS

![sp_status_screenshot](/Collateral/Screenshots/SynapseToolkit/sp_status_screenshot.png)

Sp_status runs 4 separate queries to give you an overall picture of your current workload. Some of the results provide you with the query to deep-dive further into that request’s execution.
	
### Workload state

* **resource_allocated_percentage:** The total percentage of resources utilized by all running queries. In this case there are 4 queries running, each with a 24% allocation for a total of 96% allocation. 

* **active_sessions:** The number of currently active sessions

* **idle_sessions:** The number of sessions that are not active, but have not been closed

* **running_queries:** Total number of executing queries, this does not include suspended queries. 

* **queued_queries:** Total number of queries that are in the suspended state

* **concurrency_waits:** Number of queued queries that are waiting on concurrency resources to free up. In this case there are 2 queued queries, 1 of them is waiting on concurrency. 

* **object_waits:** Number of queued queries that are waiting on objects. In this case of the 2 queued queries, one of them is queued because there is an object lock it was not able to obtain. Queries waiting on objects may later be blocked by concurrency, but they cannot proceed until they are able to get locks on the required objects. 
	
### Running Requests

This result shows all currently executing queries against your system. The result only includes queries that have an actual execution plan so it will not show parent-level queries like batches. Column-level detail for running requests can be found on the sys.dm_pdw_exec_requests documentation page. The result also provides you with two extra columns to help further investigation: 

* **request_detail_command:** Executing this query will allow you to deep-dive into the execution plan of this query. You will see the entire plan at the distribution-level along with row counts for each distribution. 
	
* **session_detail_command:** Executing this query will show you all queries for this session. 

### Suspended requests

Suspended requests shows detail about suspended queries and why they are in the suspended state. There are 4 columns added to help identify why these are queued:

* **Concurrency_waits:** A non-zero value for this column means the query is suspended because there are not enough resources free to service this request. This is related to ‘resource_allocated_percentage’ in the first result. 

* **Object_waits:** A non-zero value in this column means the query is suspended because there is at least one object it was not able to obtain a lock on

* **Waits_detail_command:** The command provided here allows you to investigate what objects are blocked and what query is blocking them. For a concurrency wait this will return no results since it is just waiting on resource percentage to free up

* **Session_detail_command:** Executing this query will show you all queries for this session

### Data Movement
This is perhaps the best indicator of what the heaviest queries currently executing are. Data movement can be a heavy operation, so queries that are performing a large amount of data movement are causing a lot of utilization of the service resources. If you are seeing resource issues and slowness, killing the first query in this result is most likely to free up resources. 

* **Step_rows_processed:** the number of rows that have been moved so far by this currently executing step of the query

* **Step_GB_Processed:** how many gigabytes of data have been moved between distributions. 

* **Request_detail_command:** Executing this command will show the entire detailed query plan for this query including data movement for each distribution on each step. 

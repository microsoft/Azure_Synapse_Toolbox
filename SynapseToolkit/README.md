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
    
## Installation

Run SynpaseToolkit.sql to create the stored procedures in dbo. If stored procedures with this name already exist they will overwrite them. 

## Using the Toolkit

Run **EXEC sp_status** to get an overview of system activity. Then use the comands provided in the last column(s) to dive deeper.

For the best experience execute with SSMS

![sp_status_screenshot](/Collateral/Screenshots/SynapseToolkit/sp_status_screenshot.png)

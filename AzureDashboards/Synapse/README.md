# Pre-Requisites

1. Existing Synapse SQL Pool not in a workspace (workspace version coming soon!)
2. Log Analytics Workspace has been created
3. In the SQL Pool you want to monitor, go to the 'Diagnostics settings' blade and create a new setting to send data to Log Analytics. You should be selecting all categories EXCEPT SQLRequests and DMSWorkers. These two DMVs are very high traffic and can be turned on only when needed to investigate an issue to save dramatically on cost. They are not used in these dashboards. 

# Deploy

You may use the button below to deploy this dashboard directly. Alternatively you can download the template from here, then in your Azure Portal use the 'Deploy a Custom Template' interface to import the template manually. This allows you to make any changes to the template before deploying. 

When filling in variables please note the following:
* databaseName should be in ALL CAPS. This is because Log Analytics queries are case-sensitive and DB name is stored in all caps. 
* For servername do not include .database.windows.net

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FAzure_Synapse_Toolbox%2Fmaster%2FAzureDashboards%2FSynapse%2FSynapseDashboardTemplateV1.4.json)

NOTE: this Dashboard will be created as a shared dashboard. You can un-share it after importing. A future version will be imported as a private dashboard. 

# Guidance

I will be providing more guidance about all of the value you can get out of this dashboard soon!

# Example

![Screenshot1](https://github.com/microsoft/Azure_Synapse_Toolbox/blob/master/AzureDashboards/Synapse/images/dashboardScreenshot1.png)
![Screenshot2](https://github.com/microsoft/Azure_Synapse_Toolbox/blob/master/AzureDashboards/Synapse/images/dashboardScreenshot2.png)
![Screenshot3](https://github.com/microsoft/Azure_Synapse_Toolbox/blob/master/AzureDashboards/Synapse/images/dashboardScreenshot3.png)

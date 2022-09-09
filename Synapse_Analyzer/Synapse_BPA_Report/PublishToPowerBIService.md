# Publish Azure Synapse Analyzer Report to Power BI service

While you can use Power BI desktop to refresh and view Azure Synapse Analyzer Report occasionally. You can set this report as a part of your operational procedure to review it on a regular basis in order to ensure you are having optimum Synapse practices implemented all the time. For scheduled report, and broader access to the report, we recommend publishing report to Power BI Service using Publish option in Power BI desktop. 

To publish pbix file to Power BI service please follow the steps outlined in [Publish from Power BI Desktop](https://docs.microsoft.com/en-us/power-bi/create-reports/desktop-upload-desktop-files "Publish from Power BI Desktop").  User publishing report may need Power BI Pro user privileges. While setting up refresh of the dataset in Power BI Service, the data source credentials used for refresh require admin rights on Synapse Dedicated pool and its databases.

To configure dataset refresh in Power BI service

1. After successfully publishing PBI desktop file, go to the premium workspace where you published the file. Click more options on the dataset and go to dataset settings 

![Dataset more info Settings](./img/Dataset-more-info-Settings.png "Dataset more info Settings")

2. Under the dataset settings, you will see error for data source. 

3. Expand parameters under settings and provide Synapse dedicated pool endpoint and database name parameters. Click Apply

![Dataset settings input parameter values](./img/Dataset-settings-input-parameter-values.png "Dataset settings input parameter values")

4. Click on “Discover Data Sources” link after you applied parameters in above step. This will populate data source information from parameters you provided.

5. You will then see option for data source credentials and Gateway connection as shown in figure below. 

![Edit Credentials option](./img/Edit-Credentials-option.png "Edit Credentials option")

6. Click Edit Credentials to provide login credentials to your Synapse Dedicated endpoint. (the credentials should have sysadmin rights on the Synapse Database)

7. If you have configured your synapse datasource to be available behind virtual private network, go to Gateway connection option and choose right gateway datasource from your gateways.  For more help on how to configure data source on gateway please see [Use the data source with Scheduled refresh](https://docs.microsoft.com/en-us/power-bi/connect-data/service-gateway-enterprise-manage-sql#use-the-data-source-with-scheduled-refresh "Use the data source with Scheduled refresh"). For more details on how to create gateway data source you can refer [Add or remove a gateway data source](https://docs.microsoft.com/power-bi/connect-data/service-gateway-data-sources "Add or remove a gateway data source").

8. After above step, now refresh dataset by clicking refresh now

![Click Refresh now](./img/Click-Refresh-now.png "Click Refresh now")


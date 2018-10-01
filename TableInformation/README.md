**Collect Table Information**

This query is used to collect various information for all tables in a database. It is especially useful for getting the index type and distribution type. 

Example output: (be sure to scroll right to see all of the output)

|	Table_Name	|	object_id	|	create_date	|	modify_date	|	Table_Type	|	Distribution_Column	|	Index_name	|	Index_Type|
| --- | --- | --- | --- | --- | --- | --- | --- |
|	AdventureWorksDWBuildVersion	|	658101385	|	36:14.7	|	36:14.7	|	REPLICATE	|	NULL	|	NULL	|	HEAP |
|	DatabaseLog	|	674101442	|	36:15.0	|	36:15.0	|	REPLICATE	|	NULL	|	ClusteredIndex_ba33114203dd42f884662c0e75eeea30	|	CLUSTERED	|
|	DimAccount	|	690101499	|	36:15.2	|	36:15.3	|	REPLICATE	|	NULL	|	ClusteredIndex_803dcf76ddc2467f98cbf403e38fc595	|	CLUSTERED	|
|	DimCurrency	|	706101556	|	36:16.3	|	36:16.3	|	REPLICATE	|	NULL	|	ClusteredIndex_50659ba6744c42839d526d3c9aa4f45a	|	CLUSTERED	|
|	DimCustomer	|	722101613	|	36:16.8	|	56:54.1	|	HASH	|	CustomerKey	|	ClusteredIndex_a35d8907e3d94ba29c2f6bf8db745f12	|	CLUSTERED	|
|	DimSalesTerritory	|	914102297	|	36:21.4	|	36:21.4	|	REPLICATE	|	NULL	|	ClusteredIndex_15718e076ba04446974e663a024c8e07	|	CLUSTERED	|
|	DimScenario	|	930102354	|	36:21.7	|	36:21.7	|	REPLICATE	|	NULL	|	ClusteredIndex_1ab882a243b041fdbf2006cb405b8be8	|	CLUSTERED	|
|	FactCallCenter	|	946102411	|	36:22.7	|	39:48.9	|	HASH	|	FactCallCenterID	|	ClusteredIndex_28dde714d85c401ab0b67d29a11304c3	|	CLUSTERED COLUMNSTORE	|
|	FactCurrencyRate	|	962102468	|	36:23.2	|	39:49.3	|	REPLICATE	|	NULL	|	ClusteredIndex_139c32f292a54e01b5abdb8c3e0b4599	|	CLUSTERED COLUMNSTORE	|
|	FactFinance	|	978102525	|	36:23.5	|	39:50.1	|	HASH	|	FinanceKey	|	ClusteredIndex_515602f9bfad4eceb28e77908bcfd0e7	|	CLUSTERED COLUMNSTORE	|





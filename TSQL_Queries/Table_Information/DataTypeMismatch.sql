SET NOCOUNT ON; 
--Identify columns that have the same name, but different data types or data lengths
WITH Query as 
(
	SELECT 
		COLUMN_NAME, 
		COUNT(DISTINCT DATA_TYPE)AS 'Diff_Type_Count' ,
		COUNT(DISTINCT Character_Maximum_length) AS 'Diff_Length_Count', 
		count(table_name) AS Found_In_Table_Count
	FROM INFORMATION_SCHEMA.COLUMNS
	GROUP BY COLUMN_NAME
)
SELECT * FROM Query WHERE Diff_Type_Count > 1 or Diff_Length_Count > 1
Order by Diff_Type_Count desc,Diff_Length_Count desc

--Use this query to see all individual uses of a specific column name including data type and length
SELECT 
	TABLE_SCHEMA,
	TABLE_NAME, 
	COLUMN_NAME, 
	DATA_TYPE, 
	Character_Maximum_length
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME = 'SEQ_NUM' --Change to column name to investigate
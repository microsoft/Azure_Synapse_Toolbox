SET NOCOUNT ON; 
--This query will find tables with the most number of large types
SELECT TABLE_SCHEMA,TABLE_NAME, COUNT(*) AS Num_Lg_Types
FROM INFORMATION_SCHEMA.COLUMNS
WHERE Character_Maximum_length > 100
GROUP BY TABLE_SCHEMA,TABLE_NAME
order by Num_Lg_Types desc
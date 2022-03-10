SET NOCOUNT ON;
--This query will just collect the largest data types it can find in the database. 
--You can change the character maximum length as desired
SELECT TABLE_SCHEMA,TABLE_NAME, COLUMN_NAME, DATA_TYPE, Character_Maximum_length
FROM INFORMATION_SCHEMA.COLUMNS
WHERE Character_Maximum_length > 100
order by Character_Maximum_length desc


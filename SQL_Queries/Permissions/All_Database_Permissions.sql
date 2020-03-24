--This query will list ALL PERMISSIONS in the database. It includes permissions granted to principals through role membership and permissions granted explicitly to principals. 
--It also includes all role membership whether or not permissions are granted through that role. In this case the permission columns will be NULL.
SELECT DB_NAME() AS 'Database',* FROM 
(
--List permissions granted outside of database roles
SELECT 
       prin.name AS 'Database_Principal',
       '<explicit>' AS 'Permission_Derived_From',
       prin.type_desc AS 'Principal_Type',
       prin.authentication_type_desc AS 'Authnetication',
       perm.state_desc AS 'Action',
       perm.permission_name AS 'Permission',
    CASE perm.class
      WHEN 0 THEN 'Database::' + DB_NAME()
      WHEN 1 THEN OBJECT_NAME(perm.major_id)
      WHEN 3 THEN 'Schema::' + SCHEMA_NAME(perm.major_id) END AS 'Securable'
       from sys.database_principals prin
JOIN sys.database_permissions perm
ON prin.principal_id = perm.grantee_principal_id


UNION ALL

--List Database Role Members and their derived permission
SELECT 
   DP2.name AS 'Database_Principal', 
       DP1.name AS 'Permission_Derived_From', 
       DP2.type_desc AS 'Principal_Type',
       DP2.authentication_type_desc AS 'Authnetication',
   CASE DP1.name
              WHEN 'db_owner' THEN 'IMPLICIT - FDR'
              WHEN 'db_ddladmin' THEN 'IMPLICIT - FDR'
              WHEN 'db_datareader' THEN 'IMPLICIT - FDR'
              WHEN 'db_datawriter' THEN 'IMPLICIT - FDR'
              WHEN 'db_securityadmin' THEN 'IMPLICIT - FDR'
              WHEN 'db_accessadmin' THEN 'IMPLICIT - FDR'
              WHEN 'db_backupoperator' THEN 'IMPLICIT - FDR'
              WHEN 'db_denydatawriter' THEN 'IMPLICIT - FDR'
              WHEN 'db_denydatareader' THEN 'IMPLICIT - FDR' 
              ELSE pe.state_desc END AS 'Action',
   CASE DP1.name
              WHEN 'db_owner' THEN 'CONTROL'
              WHEN 'db_ddladmin' THEN 'CREATE, DROP, ALTER ON ANY OBJECTS'
              WHEN 'db_datareader' THEN 'SELECT'
              WHEN 'db_datawriter' THEN 'INSERT,UPDATE,DELETE'
              WHEN 'db_securityadmin' THEN 'Mange Role Membership and perms'
              WHEN 'db_accessadmin' THEN 'GRANT/REVOKE access to users/roles'
              WHEN 'db_backupoperator' THEN 'Can BACKUP DB'
              WHEN 'db_denydatawriter' THEN 'DENY INSERT,UPDATE,DELETE'
              WHEN 'db_denydatareader' THEN 'DENY SELECT' 
              ELSE pe.permission_name END AS 'Permission',
   CASE pe.class
      WHEN 0 THEN 'Database::' + DB_NAME()
      WHEN 1 THEN OBJECT_NAME(pe.major_id)
      WHEN 3 THEN 'Schema::' + SCHEMA_NAME(pe.major_id) 
         ELSE 'Database::' + DB_NAME() END AS 'Securable'
FROM sys.database_role_members AS DRM  
RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
LEFT JOIN sys.database_permissions AS pe  
    ON pe.grantee_principal_id = DP1.principal_id
WHERE DP1.type = 'R'
AND DP2.name IS NOT NULL
) perms ORDER BY Permission

SET
    NOCOUNT ON 
	DROP TABLE dbo.Employee;

GO

CREATE TABLE dbo.Employee (
    EmployeeId BIGINT NOT NULL,
    EmployeeName VARCHAR(255) NOT NULL,
    ParentId BIGINT NOT NULL
) WITH (
    DISTRIBUTION = HASH (EmployeeId),
    HEAP
);

GO
insert into
    Employee
values
(10, 'Ken Sánchez', 1);

insert into
    Employee
values
(11, 'Brian Welker', 10);

insert into
    Employee
values
(12, 'Stephen Jiang', 11);

insert into
    Employee
values
(13, 'Michael Blythe', 2);

insert into
    Employee
values
(14, 'Linda Mitchell', 13);

insert into
    Employee
values
(15, 'Syed Abbas', 3);

insert into
    Employee
values
(16, 'Lynn Tsoflias', 15);

insert into
    Employee
values
(17, 'David Bradley', 16);

insert into
    Employee
values
(18, 'Hanan Almira', 17);

insert into
    Employee
values
(19, 'Yunia Damayanti', 18);

insert into
    Employee
values
(20, 'Mike Decker', 19);

insert into
    Employee
values
(21, 'Lovely Sugiyanti', 12);

GO
SELECT
    *
FROM
    dbo.Employee f 
	


-- Insert first record where no parent exists
IF OBJECT_ID('tempdb..#employee') IS NOT NULL DROP TABLE #employee;
CREATE TABLE #employee
WITH (
    DISTRIBUTION = HASH (EmployeeId)
) AS 

WITH cte AS (
    SELECT
        1 AS xlevel,
        p.EmployeeId,
        p.ParentId,
        p.EmployeeName,
        CAST(p.ParentId AS VARCHAR(255)) AS PathString,
        0 AS PathLength,
		1 as IsRoot,
		Case when exists (Select 1 from dbo.employee pcheck where pcheck.ParentId = p.EmployeeID) then 0 else 1 end as IsLeaf
    FROM
        dbo.Employee p
    WHERE
        NOT EXISTS (
            SELECT
                *
            FROM
                dbo.Employee c
            WHERE
                p.ParentId = c.EmployeeId
        )
)
SELECT
    *
FROM
    cte


SELECT
    'before' s,
    *
FROM
    #employee 
ORDER BY EmployeeId;

-- Loop thru Features
DECLARE @counter int = 1;

--Begin Loop
WHILE EXISTS (
    SELECT
        *
    FROM
        #employee p
        INNER JOIN dbo.employee c ON p.EmployeeId = c.ParentId
    WHERE
        p.xlevel = @counter
)	
BEGIN -- Insert next level
	INSERT INTO
		#employee ( xlevel, EmployeeId, ParentId, EmployeeName, PathString, PathLength, IsRoot, IsLeaf )
	SELECT
		@counter + 1 AS xlevel,
		c.EmployeeId,
		c.ParentId,
		c.EmployeeName,
		p.PathString + '*' + CAST(c.ParentId AS VARCHAR(255)) AS PathString,
		@counter AS PathLength,
		0 as IsRoot,
		Case when exists (Select 1 from dbo.employee pcheck where pcheck.ParentId = C.EmployeeID) then 0 else 1 end as IsLeaf
	FROM
		#employee p
		INNER JOIN dbo.employee c ON p.EmployeeId = c.ParentId
	WHERE
		p.xlevel = @counter;

	SET @counter = @counter + 1;

	-- Loop safety
	IF @counter > 99 
	BEGIN 
		RAISERROR('Too many loops!', 16, 1) 
		BREAK
	END
END

SELECT
    *
FROM
    dbo.Employee f 
	

SELECT
    'after' s,
    *
FROM
    #employee ORDER BY EmployeeId;

--Get Leaf Rows
SELECT
    'after' s,
    *
FROM
    #employee  e
Where not exists (select parentid from #Employee p where e.employeeid = p.parentid)
USE Comm4;
GO

SELECT DISTINCT

CASE
	WHEN sacc.RoleID=1 THEN 'Attending'
	WHEN sacc.RoleID=2 THEN 'Resident'
	WHEN sacc.RoleID=3 THEN 'Editor'
	WHEN sacc.RoleID=4 THEN 'Technologist'
	WHEN sacc.RoleID=5 THEN 'FrontDesk'
	WHEN sacc.RoleID=6 THEN 'OrderEntry'
	WHEN sacc.RoleID=7 THEN 'Fellow'
ELSE 'Unassigned' 
END AS [Assigned Role],
acct.LoginName,
acct.LastLoginDate,
CASE 
	WHEN acct.IsActive=1 THEN 'Yes'
ELSE 'No'
End AS [Active User],
CASE 
	WHEN acct.IsAdmin=1 THEN 'Yes'
ELSE 'No'
END AS [Admin ?],
CASE 
	WHEN ae.RealmID=1 THEN 'Client'
	WHEN ae.RealmID=3 THEN 'Portal'
ELSE 'Not Applicable'
END AS [Application In Use],
ae.Workstation

FROM Account AS acct
	LEFT JOIN SiteAccount AS sacc ON acct.AccountID=sacc.AccountID
	LEFT JOIN AccountEvent AS ae ON acct.AccountID=ae.AccountID 

WHERE acct.LastLoginDate BETWEEN '2016-01-01 00:00:00.000' AND '2016-07-19 23:59:00.000'
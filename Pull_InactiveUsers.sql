USE Comm4;
GO

SELECT
a.AccountID,
sa.RoleID, 
p.LastName, 
p.FirstName, 
a.LoginName,
a.LastLoginDate, 
s.Name, 
s.SiteID

FROM [Account] (Nolock) AS a

JOIN SiteAccount (Nolock) AS sa ON a.AccountID = sa.AccountID
JOIN [Site] (Nolock) AS s ON s.SiteID = sa.SiteID
JOIN PersonalInfo (Nolock) AS p ON a.PersonalInfoID = p.PersonalInfoID

WHERE a.IsActive = 0
AND sa.RoleID IN (1,2,7)
AND a.AccountID != 0
AND a.LastLoginDate <= DATEADD(DAY,-2000,GETDATE())

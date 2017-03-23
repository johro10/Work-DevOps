USE Comm4;
GO

SELECT

	--ae.AccountEventID,
	--ae.AccountEventTypeID,
	aet.Name AS [Event Action],
	aet.[Description],
	ae.AccountID,
	act.LoginName,
	ae.AdminAccountID,
	ae.EventTime,
	ae.AdditionalInfo,
	ae.Workstation,
	ae.RealmID

FROM AccountEvent AS ae

	LEFT OUTER JOIN AccountEventType AS aet ON ae.AccountEventTypeID = aet.AccountEventTypeID
	LEFT OUTER JOIN Account AS act ON ae.AccountID = act.AccountID

--WHERE AccountID = 1490

ORDER BY EventTime DESC

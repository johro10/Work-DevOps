USE comm4; go
SELECT loginname,
         lastlogindate,
         ae.EventTime,
         aet.Name
FROM Account AS act
LEFT JOIN AccountEvent AS ae
    ON act.AccountID = ae.AccountID
LEFT JOIN AccountEventType AS aet
    ON ae.AccountEventTypeID = aet.AccountEventTypeID
WHERE isadmin = 1
        AND ( lastlogindate
    BETWEEN '2016-01-14 08:00:00.000'
        AND '2016-11-21 11:30:00.000' )
ORDER BY  lastlogindate DESC 
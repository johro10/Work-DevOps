USE Comm4;
GO

SELECT *
FROM Account
WHERE LoginName = 'robAttending'


UPDATE Account

SET Password = 'ukEYLUAtnyn3LuPUunBxmg==', LastPWChangeDate = CURRENT_TIMESTAMP WHERE LoginName = 'robattending'
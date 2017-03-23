SELECT
 
Acct.AccountID,
Acct.LoginName,
CASE WHEN Acct.IsActive = 1 THEN 'Yes' ELSE 'No'
END AS [Active Yes/No],
LM.Name

FROM Account AS Acct

LEFT OUTER JOIN AccountSpeaker AS Spkr ON Acct.AccountID = Spkr.AccountID
LEFT OUTER JOIN LanguageModel AS LM ON Spkr.LanguageModelID = LM.LanguageModelID
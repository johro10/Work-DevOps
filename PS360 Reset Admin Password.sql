/* Reset password to "" */
Update Comm4..Account
Set Password = '', IsActive = 1, LastLoginDate = GetDate()
Where AccountID = 1

Delete From Comm4..AccountEvent
Where AccountEventTypeID = 3
    And AccountID = 1

If Object_ID('tempdb..#TempFinal', 'U') Is Not Null Drop Table #TempFinal
Create Table #TempFinal
(
    AccountID int,
    LastName varchar(50),
    FirstName varchar(50),
    LoginName varchar(50),
    Report_Count int,
    Report_LastCreate datetime,
    SiteName varchar(50),
    SiteID int
)

If Object_ID('tempdb..#TempReport', 'U') Is Not Null Drop Table #TempReport
Create Table #TempReport
(
    AccountID int,
    LastRun datetime,
    Report_Count int,
    SiteID int
)

If Object_ID('tempdb..#TempFinalS', 'U') Is Not Null Drop Table #TempFinalS
Create Table #TempFinalS
(
    AccountID int,
    LastName varchar(50),
    FirstName varchar(50),
    LoginName varchar(50),
    Report_Count int,
    Report_LastCreate datetime
)

Insert Into #TempFinal
    (AccountID, LastName, FirstName, LoginName, SiteName, SiteID)
Select a.AccountID, p.LastName, p.FirstName, a.LoginName, s.Name, s.SiteID
From Comm4..Account (Nolock) a
    Join Comm4..SiteAccount (Nolock) sa On a.AccountID = sa.AccountID
    Join Comm4..Site (Nolock) s On s.SiteID = sa.SiteID
    Join Comm4..PersonalInfo (Nolock) p On a.PersonalInfoID = p.PersonalInfoID
Where a.IsActive = 1
    And sa.RoleID in (1,2,7)
    And a.AccountID != 1
    And a.LastLoginDate >= DateAdd(month,-2,GETDATE())
Group By a.AccountID, p.LastName, p.FirstName, a.LoginName, s.Name, s.SiteID
Order By 1

Insert Into #TempReport
    (AccountID, SiteID, LastRun, Report_Count)
Select tf.AccountID, tf.SiteID, MAX(r.CreateDate),
    SUM(Case When r.CreatorAcctID is Not Null Then 1 Else 0 End) As 'Report_Count'
From #TempFinal tf
    Join Comm4..Report r On (r.CreatorAcctID = tf.AccountID And r.SiteWorkTypeID = tf.SiteID)
Group By tf.AccountID, tf.SiteID

Update #TempReport
Set Report_Count = Coalesce(Total.ReportCount, 0)
From #TempReport (Nolock) tr
    Left Outer Join (Select r.CreatorAcctID, COUNT(*) As 'ReportCount'
    From Comm4..Report (Nolock) r
        Join #TempReport (Nolock) trep On trep.AccountID = r.CreatorAcctID
        Join Comm4..SiteWorktype (Nolock) sw On sw.SiteWorktypeID = r.SiteWorktypeID
        Join Comm4..Site (Nolock) s On s.SiteID = sw.SiteID
    Where r.CreateDate>=DATEADD(month,-2,GETDATE())
    Group By r.CreatorAcctID) As Total
    On Total.CreatorAcctID = tr.AccountID

Update tf
Set tf.Report_Count = tr.Report_Count, tf.Report_LastCreate = tr.LastRun
From #TempFinal tf
    Left Outer Join #TempReport tr On (tf.AccountID = tr.AccountID And tf.SiteID = tr.SiteID)

Insert Into #TempFinalS
    (AccountID, LastName, FirstName, LoginName)
Select Distinct(tf.AccountID), tf.LastName, tf.FirstName, tf.LoginName
From #TempFinal (Nolock) tf
Order By 1

Update tfs
Set tfs.Report_Count = Total.ReportCount
From #TempFinalS (Nolock) tfs
    Left Outer Join (Select tf.AccountID, Sum(tf.Report_Count) 'ReportCount'
    From #TempFinal (Nolock) tf
    Group By tf.AccountID) As Total
    On Total.AccountID = tfs.AccountID

Update tfs
Set tfs.Report_LastCreate = Total.ReportLastCreate
From #TempFinalS (Nolock) tfs
    Left Outer Join (Select tf.AccountID, Max(tf.Report_LastCreate) 'ReportLastCreate'
    From #TempFinal (Nolock) tf
    Group By tf.AccountID) As Total
    On Total.AccountID = tfs.AccountID

    Select tf.SiteName, Sum(Case When tf.Report_Count Is Not Null Then 1 Else 0 End) 'Active Users', Sum(Case When tf.Report_Count Is Null Then 1 Else 0 End) 'Inactive Users',
        Sum(Case When tf.Report_Count Is Null Then 1 When tf.Report_Count Is Not Null Then 1 End) 'Total Users'
    From #TempFinal tf
    Group By tf.SiteName

Union All

    Select 'System Wide', Sum(Case When tfs.Report_Count Is Not Null Then 1 Else 0 End) 'Active Users', Sum(Case When tfs.Report_Count Is Null Then 1 Else 0 End) 'Inactive Users',
        Sum(Case When tfs.Report_Count Is Null Then 1 When tfs.Report_Count Is Not Null Then 1 End) 'Total Users'
    From #TempFinalS tfs

Drop Table #TempFinal
Drop Table #TempReport
Drop Table #TempFinalS

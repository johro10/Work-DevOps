/* 
Remove Site script
   
   This script removes a specific sites referenced data 
   from a Health system.

   Back up DB first as this can not be undone.
   Run this in a test environment first
   To run this Script, all users must be off the system and Interfaces stopped.
   To begin edit this entry <ENTER SITE NAME> below with the proper site name.

   Last Modified 2016/11/07

*/
USE [comm4]
GO

Declare @SiteName nvarchar(100)
		,@SiteID int
		,@count int
		,@startTime datetime;

Set @SiteName = '<ENTER SITE NAME HERE>';

set @startTime = GETDATE();

Select @SiteID = SiteID
from Site
where Name = @SiteName;
if @SiteID is null raiserror('!!!!!! A SITE WITH THIS NAME NOT EXISTS !!!!!!', 20, -1) with log

Select @count=count(*)
from [Order] o inner join Visit v on v.VisitID = o.VisitID
	inner join Patient p on p.PatientID = v.PatientID
where p.SiteID = @siteID
Print cast(getdate() as varchar) + ' - Total Number of Orders in "' + @SiteName + '" site: ' + str(@count)

Print cast(getdate() as varchar) + ' - Starting Wipe out: ' + cast(getdate() as varchar)

--DISABLE triggers to speed up process
ALTER TABLE [ORDER] DISABLE TRIGGER ALL;
ALTER TABLE [Visit] DISABLE TRIGGER ALL;
ALTER TABLE [Patient] DISABLE TRIGGER ALL;
ALTER TABLE [Report] DISABLE TRIGGER ALL;
ALTER TABLE [OrderProcedure] DISABLE TRIGGER ALL;

--Lets Truncate ExplorerSnapshot
TRUNCATE TABLE ExplorerSnapshot;


--Remedy Scripts
--1.We should first check if there are Db inconsistencies between report sitework type and patient site

Update r set r.SiteWorkTypeID = swt2.SiteWorkTypeID  from report r inner join [order] o on o.LastReportID = r.ReportID
	inner join SiteWorkType swt on swt.SiteWorkTypeID = r.SiteWorkTypeID
	inner join Visit v on v.VisitID = o.VisitID inner join patient p on p.PatientID = v.PatientID
	inner join SiteWorkType swt2 on swt2.SiteID = p.SiteID
where swt.SiteID <> p.SiteID;

Print cast(getdate() as varchar) + ' - Site Work Type 1 Remedy: ' + str(@@RowCount);

Update r set r.SiteWorkTypeID = swt2.SiteWorkTypeID  from report r inner join [order] o on o.ReportID = r.ReportID
	inner join SiteWorkType swt on swt.SiteWorkTypeID = r.SiteWorkTypeID
	inner join Visit v on v.VisitID = o.VisitID inner join patient p on p.PatientID = v.PatientID
	inner join SiteWorkType swt2 on swt2.SiteID = p.SiteID
where swt.SiteID <> p.SiteID;

Print cast(getdate() as varchar) + ' - Site Work Type 2 Remedy: ' + str(@@RowCount);

--We need to store temporarily the IDs of the reports in the specific site
if EXISTS (SELECT *
FROM tempdb.sys.tables
WHERE name = '##tmpReportIDs')
DROP Table [##tmpReportIDs];

CREATE TABLE [##tmpReportIDs]
(
	ReportID int not null Primary Key
);

insert into [##tmpReportIDs]
	(ReportID)
Select Distinct ReportID
from [Order] o inner join Visit v on v.VisitID = o.VisitID
	inner join Patient p on p.PatientID = v.PatientID
where p.SiteID = @SiteID and ReportID is not null;

Print cast(getdate() as varchar) + ' - Added rows in tmp: ' + str(@@RowCount);

--This has only created a list of original reports.
--Now we need to add adendums as well
insert into [##tmpReportIDs]
	(ReportID)
select ra.AddendumReportID
from [ReportAddendum] ra
	inner join [##tmpReportIDs] t on t.ReportID = ra.OriginalReportID;

Print cast(getdate() as varchar) + ' - Added addendums in tmp: ' + str(@@RowCount);
--Now we should start removing

--OrderProcedure
DELETE op from OrderProcedure op inner join ProcedureCode pc
	on pc.ProcedureCodeID = op.ProcedureCodeID where pc.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - OrderProcedure: ' + str(@@RowCount);

--AdminEvent
DELETE FROM AdminEvent where SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - AdminEvent: ' + str(@@RowCount);

/* Report - cascades to 
ReportAttachment
ReportAudio
ReportCDSGuidance
ReportContributor
ReportEvent
ReportFinding
ReportNLUResult
ReportNote
ReportNUSSession
ReportReview
ReportAddendum
OrderClinicalCode
OrderCustomField
ExplorerSnapshot
AutoTextUsage
BridgeEvent

*/


--First release Order Dependence
UPDATE [Order] set ReportID = null, LastReportID = null
from [Order] inner join [##tmpReportIDs] r on r.ReportID = [order].ReportID;

Print cast(getdate() as varchar) + ' - Order Update 1: ' + str(@@RowCount)

UPDATE [Order] set ReportID = null, LastReportID = null
from [Order] inner join [##tmpReportIDs] r on r.ReportID = [order].LastReportID;

Print cast(getdate() as varchar) + ' - Order Update 2: ' + str(@@RowCount);

--Clear OriginalReportID from Reports
Update Report Set OriginalReportID = null
from Report inner join [##tmpReportIDs] r on r.ReportID = Report.ReportID;

Print cast(getdate() as varchar) + ' - Report Update - OriginalReportID: ' + str(@@RowCount);

--Delete addendums
DELETE ra from ReportAddendum ra
	inner join [##tmpReportIDs] r on ra.OriginalReportID = r.ReportID;

Print cast(getdate() as varchar) + ' - Delete Addendums 1: ' + str(@@RowCount);

--Delete DeletedReportEvent
DELETE ra from DeletedReportEvent ra
	inner join [##tmpReportIDs] r on ra.ReportID = r.ReportID;

Print cast(getdate() as varchar) + ' - Delete Addendums 2: ' + str(@@RowCount);

--Delete CommunEvent
DELETE ra from CommunEvent ra
	inner join [##tmpReportIDs] r on ra.ReportID = r.ReportID;

Print cast(getdate() as varchar) + ' - Commun Event: ' + str(@@RowCount);

--Delete Report Bridge Message
DELETE ra from BridgeMessage ra
	inner join [##tmpReportIDs] r on ra.ReportID = r.ReportID;

Print cast(getdate() as varchar) + ' - Report Bridge Message: ' + str(@@RowCount);

--Delete AccountSession
DELETE ra from AccountSession ra
	inner join ReportEvent re on re.ReportEventID = ra.LastReportEventID
	inner join [##tmpReportIDs] r on re.ReportID = r.ReportID;

Print cast(getdate() as varchar) + ' - Account Session: ' + str(@@RowCount);

--Delete report
--Deactivate self reference to Original Report ID
IF  EXISTS (SELECT *
FROM sys.foreign_keys
WHERE object_id = OBJECT_ID(N'Report_Report_FK1'))
	ALTER TABLE [Report] NOCHECK CONSTRAINT [Report_Report_FK1];

DELETE ra from Report ra
	inner join [##tmpReportIDs] r on ra.ReportID = r.ReportID;

Print cast(getdate() as varchar) + ' - Delete report: ' + str(@@RowCount);

DELETE ra from Report ra inner join SiteWorkType sw on sw.SiteWorkTypeID = ra.SiteWorkTypeID
where sw.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Delete report - Orphans: ' + str(@@RowCount);

IF  EXISTS (SELECT *
FROM sys.foreign_keys
WHERE object_id = OBJECT_ID(N'[Report_Report_FK1]'))
	ALTER TABLE [Report] CHECK CONSTRAINT [Report_Report_FK1];

--6. Delete SiteNUSCriticalResultException 
--DELETE FROM SiteNUSCriticalResultException where SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Delete SiteNUSCriticalResultException: ' + str(@@RowCount);

--We need to store temporarily the IDs of the Orders in the specific site
if EXISTS (SELECT *
FROM tempdb.sys.tables
WHERE name = '##tmpOrderIDs')
DROP Table [##tmpOrderIDs];

CREATE TABLE [##tmpOrderIDs]
(
	OrderID int not null Primary Key
);

insert into [##tmpOrderIDs]
	(OrderID)
Select Distinct OrderID
from [Order] o inner join Visit v on v.VisitID = o.VisitID
	inner join Patient p on p.PatientID = v.PatientID
where p.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Insert into order tmp: ' + str(@@RowCount);

--Bridge Event 
DELETE ra from BridgeEvent ra
	inner join [##tmpOrderIDs] r on ra.OrderID = r.OrderID;

--Bridge Message
DELETE ra from BridgeMessage ra
	inner join [##tmpOrderIDs] r on ra.OrderID = r.OrderID;

Print cast(getdate() as varchar) + ' - Delete BridgeMessage: ' + str(@@RowCount);

--Deleted Order Event
DELETE ra from DeletedOrderEvent ra
	inner join [##tmpOrderIDs] r on ra.OrderID = r.OrderID;

Print cast(getdate() as varchar) + ' - Delete DeletedOrderEvent: ' + str(@@RowCount);

--Order Event
DELETE ra from OrderEvent ra
	inner join [##tmpOrderIDs] r on ra.OrderID = r.OrderID;

Print cast(getdate() as varchar) + ' - Delete OrderEvent: ' + str(@@RowCount);

--Visit Bridge Events
DELETE ra from BridgeEvent ra
	inner join Visit v on v.VisitID = ra.VisitID
	inner join Patient p on p.PatientID = v.PatientID
where p.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Delete BridgeEvent - Visit: ' + str(@@RowCount);

--Patient Bridge Events
DELETE ra from BridgeEvent ra
	inner join Patient p on p.PatientID = ra.PatientID
where p.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Delete BridgeEvent - patient: ' + str(@@RowCount);

--Remove SiteLocation Dependency from visit
UPDATE Visit set SiteLocationID = null 
FROM Visit v inner join SiteLocation sl on sl.SiteLocationID = v.SiteLocationID
where sl.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Update Visit Location: ' + str(@@RowCount);

/*
	Patient Personal Info
*/
--We need to store temporarily the IDs of the PatientPersonalInfo in the specific site
if EXISTS (SELECT *
FROM tempdb.sys.tables
WHERE name = '##tmpPersonalInfo')
DROP Table [##tmpPersonalInfo];

CREATE TABLE [##tmpPersonalInfo]
(
	PersonalInfoID int not null Primary Key
);

insert into [##tmpPersonalInfo]
	(PersonalInfoID)
	Select o.PersonalInfoID
	from [PersonalInfo] o inner join Patient p on p.PersonalInfoID = o.PersonalInfoID
	where p.SiteID = @SiteID
except
	Select o.PersonalInfoID
	from [##tmpPersonalInfo] o;

Print cast(getdate() as varchar) + ' - Insert into PersonalInfo - Patient tmp: ' + str(@@RowCount);

insert into [##tmpPersonalInfo]
	(PersonalInfoID)
	Select o.PersonalInfoID
	from [PersonalInfo] o inner join InsuranceInfo ii on ii.InsuredPersonalInfoID = o.PersonalInfoID
		inner join PatientInsuranceInfo ppi on ppi.InsuranceInfoID = ii.InsuranceInfoID
		inner join Patient p on p.PatientID = ppi.PatientID
	where p.SiteID = @SiteID
except
	Select o.PersonalInfoID
	from [##tmpPersonalInfo] o;

Print cast(getdate() as varchar) + ' - Insert into PersonalInfo - Patient Indurance tmp: ' + str(@@RowCount);

/*
	Delete Site - cascades:
	
	AccountReviewCount
	CustomFieldKey
	DeletedOrderEvent
	DeletedReportEvent
	Patient
	SiteAutoText
	SiteBridge
	SiteClinicalCode
	SiteNUSCriticalResultException	No
	SitePACS
	SiteReviewCategory
	SiteReviewCustomField
	SiteSection
	SiteTemplate
	SiteWorkType

*/

DROP Table [##tmpReportIDs];
DROP Table [##tmpOrderIDs];

--Remendy Script
--2. Order Site and patient Site
Update o Set o.siteID = p.SiteID from
	[Order] o inner join visit v on v.VisitID = o.VisitID
	inner join patient p on p.PatientID = v.PatientID
where o.SiteID <> p.SiteID;

--Order Site and Custom Field key site
Update ofk set ofk.siteID = o.siteID 
from CustomFieldKey ofk inner join OrderCustomField ocf on ocf.CustomFieldKeyID  = ofk.CustomFieldKeyID
	inner join [order] o on o.OrderID = ocf.OrderID 
where o.SiteID <> ofk.SiteID and ofk.SiteID = @SiteID

Print cast(getdate() as varchar) + ' - Order - Patient Remedy: ' + str(@@RowCount);

Delete o from [order] o where siteid = @SiteID;
Print cast(getdate() as varchar) + ' - Delete Order: ' + str(@@RowCount);

--remedy Script
--3. Visit Site

Delete v from visit v inner join Patient p on p.PatientID = v.PatientID
where p.SiteID = @SiteID;

Print cast(getdate() as varchar) + ' - Delete Visit: ' + str(@@RowCount);

Delete p from Patient p where p.SiteID = @SiteID;
Print cast(getdate() as varchar) + ' - Delete Patient: ' + str(@@RowCount);

DELETE pif from PersonalInfo pif
	inner join [##tmpPersonalInfo] t on t.PersonalInfoID = pif.PersonalInfoID
where pif.PersonalInfoID not in (
	select PersonalInfoID
	from Account
union all
	select PersonalInfoID
	from Physician
);

Print cast(getdate() as varchar) + ' - Delete Personal Info: ' + str(@@RowCount);

DROP Table [##tmpPersonalInfo];

ALTER TABLE [ORDER] ENABLE TRIGGER ALL;
ALTER TABLE [Visit] ENABLE TRIGGER ALL;
ALTER TABLE [Patient] ENABLE TRIGGER ALL;
ALTER TABLE [Report] ENABLE TRIGGER ALL;
ALTER TABLE [OrderProcedure] ENABLE TRIGGER ALL;

--Rebuild Snapshot
Exec ResetExplorerSnapshot;

--Remove Orphan Audio
Delete from audio with (ROWLOCK)
where AudioID in 
(
Select AudioID
FROM Audio with (NOLOCK)
WHERE AudioID not in 
(
		SELECT AudioID
	FROM ReportAudio WITH (NOLOCK)
	WHERE NOT AudioID IS NULL
UNION ALL
	SELECT AudioID
	FROM ReportEventContent WITH (NOLOCK)
	WHERE NOT AudioID IS NULL
UNION ALL
	SELECT AudioID
	FROM Note WITH (NOLOCK)
	WHERE NOT AudioID IS NULL
)
);
Print cast(getdate() as varchar) + ' - Delete Audio: ' + str(@@RowCount);
--Remove Orphan Notes
Delete from Note with (ROWLOCK)
where NoteID in 
(
Select NoteID
FROM Note with (NOLOCK)
WHERE NoteID not in 
(
		SELECT NoteID
	FROM PatientNote WITH (NOLOCK)
UNION ALL
	SELECT NoteID
	FROM ReportNote WITH (NOLOCK)
UNION ALL
	SELECT NoteID
	FROM OrderNote WITH (NOLOCK)
)
);
Print cast(getdate() as varchar) + ' - Delete Notes: ' + str(@@RowCount);
--Remove Orphan Attachments
Delete from Attachment with (ROWLOCK)
where AttachmentID in 
(
Select AttachmentID
FROM Attachment with (NOLOCK)
WHERE AttachmentID not in 
(
		SELECT AttachmentID
	FROM PatientAttachment WITH (NOLOCK)
UNION ALL
	SELECT AttachmentID
	FROM ReportAttachment WITH (NOLOCK)
UNION ALL
	SELECT AttachmentID
	FROM OrderAttachment WITH (NOLOCK)
)
);

Print cast(getdate() as varchar) + ' - Delete Attachments: ' + str(@@RowCount);

Print cast(getdate() as varchar) + ' - Finished Wipe out: ' + cast(getdate() as varchar);

Print 'Total elapsed time in sec: ' + str(datediff(second, @startTime, getdate()));
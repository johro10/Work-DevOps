/*

This script will be used to create objects required for PS360 billing after a customer upgrade and migration to a new server.
It is owned by Billing/Reporting R&D.  Any changes to the script must come from them.  Contact Nishant Shah for any questions.

This script performs the following:

1. Creates the StagingArea_RW database.  We use this database to stage the records we need to pull to bill the customer.
The database is created in the same folder as the Comm4 database.

2. Creates the tables in StagingArea_RW.  This is where we store the data to be pulled to Nuance.  There are only 2 tables - 
RW_Account and RW_TranscriptionBilling.

3. Create the stored procedures in StagingArea_RW.  These stored procedures are called from the ETL process to populate the 
tables created in step 2.

*/


/*********************************************************************************************
-- STEP 1: Create DB
**********************************************************************************************/
USE Comm4
DECLARE @Log nvarchar(500), @DB nvarchar(500)
DECLARE @SQL varchar(4000)
SELECT @DB = fileName from sysfiles where fileID = 1
SELECT @Log = fileName from sysfiles where fileID = 2
SET @DB = rtrim(@DB)
SET @Log = rtrim(@Log)
SET @DB = left(@DB,len(@DB) + 1 - charindex('\',reverse(@DB))) + 'StagingArea_RW_Data.MDF'
SET @Log = left(@Log,len(@Log) + 1 - charindex('\',reverse(@Log))) + 'StagingArea_RW_Log.LDF'

SET @SQL = 'CREATE DATABASE [StagingArea_RW]  
ON (NAME = N''StagingArea_RW_Data'', FILENAME = N''' + @DB + ''' , SIZE = 200, FILEGROWTH = 50) 
LOG ON (NAME = N''StagingArea_RW_Log'', FILENAME = N''' + @LOG + ''' , SIZE = 50, FILEGROWTH = 20)'
EXEC (@SQL)

SET @SQL = 'ALTER DATABASE [StagingArea_RW] SET RECOVERY SIMPLE' 
EXEC (@SQL)
GO

/*********************************************************************************************
-- STEP 2: Create tables
**********************************************************************************************/

USE [StagingArea_RW]
GO
/****** Object:  Table [dbo].[RW_Account]    Script Date: 03/17/2010 11:18:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RW_Account](
	[PkId] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[HealthSystemID] [int] NOT NULL,
	[PersonalInfoID] [int] NOT NULL,
	[LoginName] [varchar](50) NOT NULL,
	[Password] [varchar](200) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL CONSTRAINT [DF__Account__IsActiv__014935CB]  DEFAULT ((1)),
	[IsAdmin] [bit] NOT NULL CONSTRAINT [DF__Account__IsAdmin__023D5A04]  DEFAULT ((0)),
	[LastLoginDate] [datetime] NULL,
	[LastPWChangeDate] [datetime] NULL,
	[ADGUID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Account] PRIMARY KEY CLUSTERED 
(
	[PkId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RW_TranscriptionBilling]    Script Date: 03/17/2010 11:18:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RW_TranscriptionBilling](
	[PkId] [int] IDENTITY(1,1) NOT NULL,
	[ReportEventId] [int] NOT NULL,
	[ReportEventTypeId] [int] NOT NULL,
	[EventTime] [datetime] NOT NULL,
	[ReportEventContentId] [int] NOT NULL,
	[ContentText] [text] NULL,
	[ContentRTF] [text] NULL,
	[ReportId] [int] NOT NULL,
	[ReportStatusId] [int] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifiedDate] [datetime] NOT NULL,
	[FillerOrderNumber] [varchar](75) NULL,
	[PatientId] [int] NOT NULL,
	[PatientLastName] [varchar](50) NULL,
	[PatientFirstName] [varchar](50) NULL,
	[PatientMiddleName] [varchar](50) NULL,
	[SignerAcctId] [int] NULL,
	[SignerLastName] [varchar](50) NULL,
	[SignerFirstName] [varchar](50) NULL,
	[SignerMiddleName] [varchar](50) NULL,
	[DictatorAcctId] [int] NULL,
	[DictatorLastName] [varchar](50) NULL,
	[DictatorFirstName] [varchar](50) NULL,
	[DictatorMiddleName] [varchar](50) NULL,
	[TranscriberAcctId] [int] NULL,
	[TranscriberLastName] [varchar](50) NULL,
	[TranscriberFirstName] [varchar](50) NULL,
	[TranscriberMiddleName] [varchar](50) NULL,
	[IsAddendum] [bit] NULL,
	[SiteId] [int] NOT NULL,
	[RepStatus] [bit] NOT NULL CONSTRAINT [DF_TranscriptionBilling_RepStatus]  DEFAULT ((0)),
 CONSTRAINT [PK_TranscriptionBilling] PRIMARY KEY CLUSTERED 
(
	[PkId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

/*********************************************************************************************
-- STEP 3: Create stored procedures
**********************************************************************************************/

USE [StagingArea_RW]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Account_SEL]
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
			accountId,healthSystemId,personalInfoId,loginName,[password]
			,createDate,isActive,isAdmin,lastLoginDate,lastPWChangeDate
	FROM	comm4.dbo.account
	WHERE	1=1
END

GO


CREATE PROCEDURE [dbo].[usp_MinMaxReportEventId_SEL]
(
	@goLiveDate	datetime
	,@currMaxReportEventId	int=-1
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @minReportEventId	int
	DECLARE @maxReportEventId	int
	SET		@minReportEventId	= -1
	SET		@maxReportEventId	= -1

	SELECT	@maxReportEventId=MAX(reportEventId), @minReportEventId=MIN(reportEventId)
	FROM	comm4.dbo.transcriptionBilling
	WHERE	1=1
	AND		(ISNULL(@currMaxReportEventId,-1) = -1 OR reportEventId > @currMaxReportEventId)
	AND		lastModifiedDate >= @goLiveDate

	SELECT 	ISNULL(@maxReportEventId,-1)	AS maxReportEventId
			,ISNULL(@minReportEventId,-1)	AS minReportEventId
END

GO
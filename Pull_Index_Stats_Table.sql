USE Comm4;
GO

SELECT Name AS Index_Name,

	STATS_DATE(object_id, index_id) AS Statistics_Update_Date

FROM sys.indexes

WHERE object_id = OBJECT_ID('BridgeEvent');
GO
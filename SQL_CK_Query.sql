USE Comm4;
GO

SELECT

--V.VisitID,
S.Name,
SL.Name AS [Site Location],
P.MRN,
--V.PatientID,
V.VisitNumber AS [Visit Num],
V.AccountNumber AS [Account Num],
O.FillerOrderNumber AS [Accession],
O.PlacerOrderNumber AS [Placer Num],
O.PlacerFld1 AS [Placer Field 1],
O.FillerFld1 AS [Filler Field 1]

FROM Visit AS V

INNER JOIN [Order] AS O ON V.VisitID = O.VisitID
INNER JOIN Patient AS P ON V.PatientID = P.PatientID
INNER JOIN [Site] AS S ON P.SiteID = S.SiteID
INNER JOIN SiteLocation AS SL ON S.SiteID = SL.SiteID

WHERE
(
V.VisitNumber IS NULL OR V.AccountNumber IS NULL OR O.PlacerOrderNumber IS NULL
)

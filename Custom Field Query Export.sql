USE Comm4;

SELECT cfk.Name, cfk.[Description],


    CASE WHEN cfk.IsActive = 1 THEN 'TRUE' ELSE 'FALSE' END AS [Active],
    CASE WHEN cfk.IsRequired = 1 THEN 'TRUE' ELSE 'FALSE' END AS [Required],
    CASE WHEN cfk.IsRequiredForPrelim = 1 THEN 'TRUE' ELSE 'FALSE' END AS [Required Prelim],
    CASE WHEN cfk.IsExportable = 1 THEN 'TRUE' ELSE 'FALSE' END AS [Exportable],
    cfpc.ProcedureCodeID AS [Procedure],
    cfc.Value AS [Choice Value],
    cfc.Label AS [Choice Label],
    CASE WHEN cfc.IsActive = 1 THEN 'TRUE' ELSE 'FALSE' END AS [Choice Active]

FROM CustomFieldKey AS cfk

    LEFT OUTER JOIN CustomFieldProcedureCode AS cfpc ON cfk.CustomFieldKeyID = cfpc.CustomFieldKeyID
    LEFT OUTER JOIN CustomFieldChoice AS cfc ON cfk.CustomFieldKeyID = cfc.CustomFieldKeyID
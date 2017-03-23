WITH
  pc1_cte([procedure code], [procedure description],
    [order procedure code listing], [default autotext], [autotext name], userid 
     , modality, anatomy, [site])
  AS
  (
    SELECT PC.code             AS [Procedure Code],
      PC.[description]    AS [Procedure Code Description],
      O.procedurecodelist AS [Order Procedure Code Listing],
      CASE 
                  WHEN AT.isdefault = 1 THEN 'YES' 
                  ELSE 'NO' 
                END                 AS [Default AutoText],
      AT.NAME             AS [AutoText Name],
      ACT.loginname       AS [UserID],
      AT.modality,
      AT.anatomy,
      S.NAME              AS [Site]
    FROM autotextprocedurecode ATP
      FULL JOIN procedurecode PC
      ON ATP.procedurecodeid = PC.procedurecodeid
      FULL JOIN allautotext AT
      ON AT.autotextid = ATP.autotextid
      FULL JOIN [site] S
      ON S.siteid = PC.siteid
      FULL JOIN accountautotext AAT
      ON AT.autotextid = AAT.autotextid
      FULL JOIN account ACT
      ON AAT.accountid = ACT.accountid
      FULL JOIN orderprocedure OP
      ON ATP.procedurecodeid = OP.procedurecodeid
      FULL JOIN [order] O
      ON OP.orderid = O.orderid
  )
SELECT [procedure description],
  [order procedure code listing],
  modality,
  anatomy,
  Count([order procedure code listing]) AS Usage,
  [autotext name],
  [default autotext],
  userid,
  [site]
FROM pc1_cte
GROUP  BY [procedure description], 
          [order procedure code listing], 
          userid, 
          [autotext name], 
          [default autotext], 
          [site], 
          modality, 
          anatomy   
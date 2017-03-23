USE comm4; 

go 

SELECT DISTINCT act.loginname, 
                --CASE 
                --  WHEN act.isactive = 1 THEN 'YES' 
                --  ELSE 'NO' 
                --END AS [Active User], 
                ae.eventtime AS [Last Login],
				ae.workstation 
FROM   accountevent AS ae 
       JOIN account AS act 
         ON ae.accountid = ae.accountid 
WHERE  act.loginname = 'fm094630'
	AND ae.Workstation NOT IN ('PS360LVL5','PS360INT','PS360SPCH1','PS360SPCH2','PS360SPCH3')
	AND ae.EventTime > '2016-09-01 00:00:00.000' 
--ORDER  BY loginname, 
--          [active user] ASC   
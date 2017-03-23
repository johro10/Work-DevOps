USE spark; 

go

SELECT jobid,
    conversiontypeid,
    conversionhostid,
    [state],
    statedescription,
    uploaded,
    enqueued,
    [started],
    ended,
    progress,
    progressupdated,
    delivered,
    startat,
    resourceid
FROM job
WHERE  conversiontypeid=1
ORDER  BY enqueued DESC  
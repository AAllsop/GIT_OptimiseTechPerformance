EXEC Reporting.DropTempTablesFromSession
Declare @OutstandingDate AS DATETIME = '2018-07-06'
Declare @ResourceKey AS INT = 1630

--get all outstanding jobs
--	with no response
SELECT
	'Response' JobType
   ,ffe.ResourceKey
   ,ffe.faultid
   ,ffe.CalloutDate CalloutDateTime
   ,ffe.FirstOnSiteDate
   ,s.Latitude
   ,s.Longitude
   ,ff.StoreKey
   ,ffe.Priority
   ,ffe.ResponseTargetDate KPITargetDate
   ,1 EstimatedJobDuration
--INTO #OutstandingJobs
FROM Fault.FactFaultEvent ffe
INNER JOIN Fault.FactFaults ff
	ON ffe.faultid = ff.faultid
INNER JOIN Common.Stores s
	ON ff.StoreKey = s.StoreKey
WHERE @OutstandingDate BETWEEN ffe.CalloutDate AND ffe.FirstOnSiteDate  --OR CAST(ffe.CalloutDate AS DATE) = @OutstandingDate)
--ffe.CalloutDate >= @OutstandingDate 
AND ff.Cancelled = 0
AND ffe.Cancelled = 0
--AND ff.KPI = 1
--AND ff.FirstOnSiteDate IS NULL
AND ffe.ResourceKey = @ResourceKey 
order by ffe.FirstOnSiteDate



--identify those jobs responded to on a specific date
select top 1000 ffe.CalloutDate,ffe.FirstOnSiteDate, s.Latitude,s.Longitude, ff.StoreKey, ff.Priority, ffe.* from Fault.FactFaultEvent ffe 
Inner Join Fault.FactFaults ff
ON ffe.FaultID = ff.FaultID
Inner Join Common.Stores s
ON ff.StoreKey = s.StoreKey
WHERE ffe.ResourceKey = 1630 AND CAST(ffe.FirstOnSiteDate AS DATE) = '2018-07-06' order by ffe.FirstOnSiteDate




select top 1000 ffe.CalloutDate,ffe.FirstOnSiteDate, s.Latitude,s.Longitude, ff.StoreKey, ff.Priority, ffe.* from Fault.FactFaultEvent ffe 
Inner Join Fault.FactFaults ff
ON ffe.FaultID = ff.FaultID
Inner Join Common.Stores s
ON ff.StoreKey = s.StoreKey
WHERE ffe.ResourceKey = 1630 AND YEAR(ffe.FirstOnSiteDate) = 2018 AND MONTH(ffe.FirstOnSiteDate) = 7 order by ffe.FirstOnSiteDate




select top 1000 * from Fault.FactFaultEvent ffe
WHERE ffe.FaultID = 5749961


select CalloutDateKey CDate, COUNT(*) from Fault.FactFaultEvent WHERE ResourceKey = 8231 
AND LEFT(CalloutDateKey,6)  = 201808
group by CalloutDateKey 
order by 2 DESC



select top 1000 * from Fault.DimResources dr WHERE name = 'Grady Vangsness'

select top 1000 rmpjd.HighPriorityCallout, * from Operations.RegionalManagerPackJobData rmpjd
WHERE  YearMonth =201807
order by rmpjd.ResponseAchieved desc










--get all outstanding jobs
--	with no response
SELECT ffe.ResourceKey,COUNT(*)
FROM Fault.FactFaultEvent ffe
INNER JOIN Fault.FactFaults ff
	ON ffe.faultid = ff.faultid
INNER JOIN Common.Stores s
	ON ff.StoreKey = s.StoreKey
	Inner Join Fault.DimResources dr
	ON ffe.ResourceKey = dr.ResourceKey
WHERE ffe.Fixed = 0
AND ffe.Completed = 0
AND ff.Cancelled = 0
AND ffe.Cancelled = 0
AND ff.AlarmDateKey > 20180101
AND ff.KPI = 1
AND ff.FirstOnSiteDate IS NULL AND dr.SubType IN ('RST','RHVACT')
group by ffe.ResourceKey
order by 2 desc



















--	with no repair
INSERT INTO #OutstandingJobs
	SELECT
		'Repair' JobType
	   ,ffe.ResourceKey
	   ,ffe.faultid
	   ,ffe.CalloutDate CalloutDateTime
	   ,ff.StoreKey
	   ,s.Longitude
	   ,s.Latitude
	   ,ffe.Priority
	   ,ffe.RepairTargetDate KPITargetDate
	   ,1 EstimatedJobDuration
	FROM Fault.FactFaultEvent ffe
	INNER JOIN Fault.FactFaults ff
		ON ffe.faultid = ff.faultid
	INNER JOIN Common.Stores s
		ON ff.StoreKey = s.StoreKey
	WHERE ffe.Fixed = 0
	AND ffe.Completed = 0
	AND ff.Cancelled = 0
	AND ffe.Cancelled = 0
	AND ff.AlarmDateKey > 20180101
	AND ff.KPI = 1
	AND NOT EXISTS (SELECT
			''
		FROM #OutstandingJobs oj
		WHERE ffe.faultid = oj.faultid
		AND ffe.CalloutDate = oj.CalloutDateTime)


SELECT
	ROW_NUMBER() OVER (PARTITION BY oj.ResourceKey ORDER BY oj.JobType) GeneID
   ,*
   ,DATEDIFF(HOUR,oj.CalloutDateTime,oj.KPITargetDate) AS HoursToTarget
INTO #OutstandingJobsWithCL
FROM #OutstandingJobs oj
UNION
SELECT
	0 GeneID
   ,'Current Location' JobType
   ,ResourceKey
   ,'0' FaultID
   ,'2099-12-31' CalloutDateTime
   ,'0' StoreKey
   ,AVG(Longitude) Longitude
   ,AVG(Latitude) Latitude
   ,'Low' Priority
   ,'2099-12-31' KPITargetDate
   ,0 EstimatedJobDuration
   ,0 HoursToTarget
FROM #OutstandingJobs oj
GROUP BY ResourceKey
UNION
SELECT
	-1 GeneID
   ,'Dummy Job' JobType
   ,ResourceKey
   ,'0' FaultID
   ,'2099-12-31' CalloutDateTime
   ,'0' StoreKey
   ,0 Longitude
   ,0 Latitude
   ,'Low' Priority
   ,'2099-12-31' KPITargetDate
   ,0 EstimatedJobDuration
   ,0 HoursToTarget
FROM #OutstandingJobs oj
GROUP BY ResourceKey


SELECT
	GeneID
   ,JobType
   ,o.ResourceKey
   ,faultid
   ,CalloutDateTime
   ,StoreKey
   ,Longitude
   ,Latitude
   ,Priority
   ,KPITargetDate
   ,EstimatedJobDuration
   ,HoursToTarget
INTO dbo.OutstandingJobsForProcessing
FROM #OutstandingJobsWithCL o
Inner Join Fault.DimResources dr
ON o.ResourceKey = dr.ResourceKey
WHERE dr.SubType IN ('RST','RHVACT')
*/
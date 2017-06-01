/* Use any standard PIT database and change date range as needed */

declare @starttime VARCHAR(25)
declare @endtime VARCHAR(25)     
set @starttime = '2017-1-20 00:00'
set @endtime = '2017-1-21 00:00' 
--declare @providerId smallint  
--set @providerId = 385

drop table #rawdata
drop table #sumdup

select * into #rawdata
from pit (nolock)
where ArrivalDtUtc between @starttime and @endtime
--and CustomField2 = 'TruckPad'
--and Longitude > -32 
--and VendorID = 13200         

select UnitId, CaptureTimeUtc--, Latitude, Longitude, speed, heading
, count(*) as count_dup
into #sumdup
from #rawdata
group by UnitId, CaptureTimeUtc--, Latitude, Longitude, speed, heading
having count(*) > 1

select substring(convert(varchar,ArrivalDtUtc ,120),1,15)+'0' as [10_min_range_utc] --as arrival_hour
       ,count(*) as rows_total
       ,cast(count(distinct(unitid)) as bigint) as unique_devices
       ,sum(case when ABS(DATEDIFF(mi,arrivaldtutc,capturetimeutc)) > 2 then 1 else 0 end) as rows_latent
       ,convert(int,(convert(float,sum(case when ABS(DATEDIFF(mi,arrivaldtutc,capturetimeutc)) > 2 then 1 else 0 end)) / count(*)) * 100) as pct_latent
from #rawdata
group by substring(convert(varchar,ArrivalDtUtc ,120),1,15)+'0'--
order by 1 desc, 2 asc

;with A as
(
select min([capturetimeutc]) MinCaptureDate
,max([capturetimeutc]) MaxCaptureDate
,cast(count(*) as bigint) as TotalCount
,cast(count(distinct(unitid)) as bigint) as DistinctDeviceCount
,min(Speed) as MinSpeed, max(cast(Speed as bigint)) as MaxSpeed, avg(cast(Speed as bigint)) as AvgSpeed
,min(Heading) as MinHeading, max(cast(Heading as bigint)) as MaxHeading, avg(cast(Heading as bigint)) as AvgHeading  
,avg(cast(datediff(mi,[capturetimeutc], ArrivalDtUtc) as bigint)) AvgLatency
from #rawdata
--where providerid = @providerid   
),
B as
( 
select count(*) as LatentPoints_15Plus  
from #rawdata  
where 1=1 -- providerid = @providerid  
and datediff(minute,[capturetimeutc], ArrivalDtUtc) > 15  
),
C as
(
select count(*) as LatentPoints_Sub0  
from #rawdata 
where 1=1 -- providerid = @providerid  
and datediff(minute,[capturetimeutc], ArrivalDtUtc) < 0  
),
D as
(
select count(Speed) as NonZeroSpds   
from #rawdata
where 1=1 -- providerid = @providerid  
and Speed <> 0   
),
E as
(
select count(Speed) as ZeroSpds  
from #rawdata 
where 1=1 -- providerid = @providerid  
and Speed = 0  
),
F as
(    
--counts the # of dupes  
select sum(count_dup) as SumDupes
from #sumdup
)
select * from A,B,C,D,E,F

--calculate speed frequency
select Speed,count(1)Spd_Count  
from #rawdata 
--where providerid = @providerid  
group by Speed

--calculate total capture duration and total distinct capture times for each provider and unitid
drop table #provCapture
select unitid, COUNT(1) as Cnt, MIN(capturetimeutc) as MinArr, MAX(capturetimeutc) as MaxArr, COUNT(distinct capturetimeutc) as CntArr --providerid, 
into #provCapture
from #rawdata
group by unitid --providerid, 

--calculate average report interval and points per arrival time for each provider and unitid
drop table #provInterval
select f.*, DATEDIFF(second, minarr,maxarr)/(CntArr-1) as ReportInterval, Cnt/CntArr as VolumePerReport --providerid,
into #provInterval
from #provCapture f---, ReferenceDefs..provider p
where DATEDIFF(second, minarr,maxarr)>0
  --and f.providerid=p.providerid
  and MinArr > @starttime
order by ReportInterval, VolumePerReport desc

--calculate median report interval
SELECT  
   --providerid,  
   AVG(reportInterval) as medianInterval 
FROM  
(  
   SELECT  
      --providerid,  
      reportInterval,  
      ROW_NUMBER() OVER (  
         PARTITION BY CntArr   
         ORDER BY reportInterval ASC) AS RowAsc,
      ROW_NUMBER() OVER (  
         PARTITION BY CntArr   
         ORDER BY reportInterval DESC) AS RowDesc
   FROM #provInterval 
) x  
WHERE   
   RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)  
--GROUP BY providerid  
--ORDER BY providerid;  

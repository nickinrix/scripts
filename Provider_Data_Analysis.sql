--Use any standard PIT database and change date range as needed

declare @starttime VARCHAR(25)
declare @endtime VARCHAR(25)     
set @starttime = '2016-10-14 00:00'
set @endtime = '2016-10-15 00:00' 
--declare @providerId smallint  
--set @providerId = 385

drop table #rawdata
drop table #DupesForDust

select * into #rawdata
from pit (nolock)
where ArrivalDtUtc between @starttime and @endtime
--and CustomField2 = 'TruckPad'
--and Longitude > -32 
--and VendorID = 13200         

select Latitude, Longitude, Speed, Heading, [capturetimeutc], count(*) as Dupe_Count  
into #DupesForDust  
from #rawdata 
where 1=1-- providerid = @providerid    
and Speed <> 0  
group by Latitude, Longitude, Speed, Heading, [capturetimeutc]  
having count(*)>1  

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
select sum(Dupe_Count-1) as SumDupes
from #DupesForDust  
)
select * from A,B,C,D,E,F

select Speed,count(1)Spd_Count  
from #rawdata 
--where providerid = @providerid  
group by Speed

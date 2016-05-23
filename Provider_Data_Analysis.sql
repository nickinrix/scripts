--Run on PIT database
--declare @providerId smallint  
--set @providerId = 385

drop table #rawdata
drop table #DupesForDust

select * into #rawdata
from pit (nolock)
where ArrivalDtUtc  between '2016-1-4 18:00' and '2016-1-4 19:00'
--and Longitude > -32 
--and VendorID = 13200         
--select top 10 * from #RawData where datediff(minute,[capturetimeutc], ArrivalDtUtc) < 0  select count(*) from #rawdata where speed > 255

select Latitude, Longitude, Speed, Heading, [capturetimeutc], count(*) as Dupe_Count  
into #DupesForDust  
from #rawdata 
where 1=1-- providerid = @providerid    
and Speed <> 0  
group by Latitude, Longitude, Speed, Heading, [capturetimeutc]  
having count(*)>1  

select substring(convert(varchar,ArrivalDtUtc ,120),1,13) as arrival_hour--+'0' as [10_min_range_utc]
       ,count(*) as rows_total
       ,count(distinct unitid) as unique_devices
       ,sum(case when ABS(DATEDIFF(mi,arrivaldtutc,capturetimeutc)) > 5 then 1 else 0 end) as rows_latent
       ,convert(int,(convert(float,sum(case when ABS(DATEDIFF(mi,arrivaldtutc,capturetimeutc)) > 5 then 1 else 0 end)) / count(*)) * 100) as pct_latent
from #rawdata
group by substring(convert(varchar,ArrivalDtUtc ,120),1,13)--+'0'
order by 1 desc, 2 asc

;with A as
(
select min([capturetimeutc]) MinCaptureDt
,max([capturetimeutc]) MaxCaptureDt
,cast(count(*) as bigint) as TotalCount
,cast(count(distinct(unitid)) as bigint) as DistinctDeviceCount
,min(Speed) as MinSpeed, max(cast(Speed as bigint)) as MaxSpeed, avg(cast(Speed as bigint)) as AvgSpeed
,min(Heading) as MinHeading, max(cast(Heading as bigint)) as MaxHeading, avg(cast(Heading as bigint)) as AvgHeading  
,avg(datediff(mi,[capturetimeutc], ArrivalDtUtc)) AvgLatency
from #rawdata
--where providerid = @providerid   
),
B as
( 
select count(*) as LatentPoints_15Plus  
from #rawdata  
--where providerid = @providerid    
where datediff(minute,[capturetimeutc], ArrivalDtUtc) > 15  
),
C as
(
select count(*) as LatentPoints_Sub0  
from #rawdata 
--where providerid = @providerid    
where datediff(minute,[capturetimeutc], ArrivalDtUtc) < 0  
),
D as
(
select count(Speed) as NonZeroSpds   
from #rawdata
--where providerid = @providerid  
where Speed <> 0   
),
E as
(
select count(Speed) as ZeroSpds  
from #rawdata 
--where providerid = @providerid  
where Speed = 0  
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

--ALTER proc [dbo].[GetSpeedBias_EU] @providerID smallint, @starttime datetime, @endtime datetime --@minutes smallint,   
--as    
 /* Speed bias by provider.  */    

--set start and end times for analysis    
declare @endtime datetime    
declare @starttime datetime    
declare @providerId smallint  
declare @minutes smallint  

set @providerId = 414
set @minutes = 120  
set @endtime = '2016-09-27 16:40' --(select max(insertdtutc) from [FlowData_1] where providerid = @providerid)  
set @starttime = '2016-09-27 15:40' --dateadd(MI,-@minutes,(select max(insertdtutc) from [FlowData_1] where providerid = @providerid))  
 
drop table #FlowForAnalysis
drop table #dupesfordust  
drop table #gettargetprovider  
drop table #averagedSpeedsCompares  
drop table #averagedSpeeds  
drop table #getotherproviders  

select @providerid ProviderId, @starttime BiasStartTime, @endtime BiasEndTime  

--DNFBLAINFEU02.FlowStageEU
--Select data for given timeframe into temp table
--;with x as (
select *
into #FlowForAnalysis
from [FlowData_1]
where 1=1
and insertdtutc between @starttime and @endtime  
--), y as (
insert
into #FlowForAnalysis select *
from [FlowData_2]
where 1=1
and insertdtutc between @starttime and @endtime  
--), z as (
insert 
into #FlowForAnalysis select * 
from [FlowData_3]
where 1=1
and insertdtutc between @starttime and @endtime  
--)
--select *
--into #FlowForAnalysis
--from x,y,z


--Select the duplicates into temp table 
select Latitude, Longitude, Speed, Heading, CaptureDtUTC, count(*) as Dupe_Count  
into #DupesForDust  
from #FlowForAnalysis 
where providerid = @providerid    
and speed <> 0  
--and Type_ = 'GPS'  
group by Latitude, Longitude, Speed, Heading, CaptureDtUTC  
having count(*)>1  

;with A as
(
select min(CaptureDtUTC) MinCaptureDt, max(CaptureDtUTC) MaxCaptureDt, avg(datediff(mi,CaptureDtUTC, ArrivalDtUtc)) AvgLatency, count(*) as TotalCount, count(distinct(sensorid)) as DistinctDeviceCount,
 min(speed) as MinSpeed, max(speed) as MaxSpeed, avg(cast(heading as bigint)) as AvgHeading  
from #FlowForAnalysis
where providerid = @providerid   
),
B as
( 
select count(*) as LatentPoints_15Plus  
from #FlowForAnalysis  
where providerid = @providerid    
and datediff(minute,CaptureDtUTC, insertdtutc) > 15  
),
C as
(
select count(*) as LatentPoints_Sub0  
from #FlowForAnalysis 
where providerid = @providerid    
and datediff(minute,CaptureDtUTC, insertdtutc) < 0  
),
D as
(
select avg(speed) as AvgSpeed, count(speed) NonZeroSpds   
from #FlowForAnalysis
where providerid = @providerid  
and speed <> 0   
),
E as
(
select count(speed) ZeroSpds  
from #FlowForAnalysis 
where providerid = @providerid  
and speed = 0  
),
F as
(    
--counts the # of dupes  
select sum(Dupe_Count-1) as SumDupes
from #DupesForDust  
)
select * from A,B,C,D,E,F

  
--Speed Profile  
select speed,count(1)Spd_Count  
from #FlowForAnalysis 
where providerid = @providerid  
group by speed  
  
   
--Speed Bias  
select DATEADD (minute, (DATEDIFF(Minute, 0, CaptureDtUTC)/5)*5, 0) as CaptureDtUTC, ProviderID, EdgeID, Speed  
into #gettargetprovider  
from #FlowForAnalysis 
where providerid = @providerid  

--get rid of 0 and NULL speeds  
--I could exclude these in the main select but this way is much faster - not sure why  
delete #gettargetprovider where speed is NULL  
delete #gettargetprovider where speed = 0  
  
--now do same for other providers  
select DATEADD (minute, (DATEDIFF(Minute, 0, CaptureDtUTC)/5)*5, 0) as CaptureDtUTC, ProviderID, EdgeID, Speed  
into #getotherproviders  
from #FlowForAnalysis 
where 1=1  
and ProviderID != @providerid  
  
delete #getotherproviders where speed is NULL  
delete #getotherproviders where speed = 0  
  
--combine data from other providers who have data on the same edges at the same time as the target  
insert into #gettargetprovider  
select g.*  
from #getotherproviders g, #gettargetprovider b  
where b.CaptureDtUTC = g.CaptureDtUTC  
and b.EdgeID = g.EdgeId  
  
--average points into buckets so as not to double-count multiple dense points from the same provider  
select CaptureDtUTC, ProviderID, EdgeID,  avg(Speed) as AvgSpeed  
into #averagedSpeeds  
from #gettargetprovider --this includes all providers at this point in the processing  
group by CaptureDtUTC, ProviderID, EdgeID  

--compute the bias between the target provider and the other providers  
alter table #averagedSpeeds add BiasOfOneProvider smallint  

select #averagedSpeeds.*, frc.ReferenceSpeed, frc.FRC,  
case when AvgSpeed*100/ReferenceSpeed between 0 and 18 then 'DarkRed'  
     when AvgSpeed*100/ReferenceSpeed between 19 and 34 then 'Red'  
     when AvgSpeed*100/ReferenceSpeed between 35 and 65 then 'Yellow'  
     else 'Green' end as Color into #averagedSpeedsCompares  
from #averagedSpeeds inner join RoadSegment..EdgeRoadSegment edge -- ReferenceDefs..Link edge
on #averagedSpeeds.EdgeID = edge.EdgeID  
--join ReferenceDefs.dbo.LinkProperty lp on edge.LinkPropertyID = lp.LinkPropertyID 
inner join RoadSegment..RoadSegmentTMC tmc  
on edge.RoadSegmentID=tmc.RoadSegmentID  
inner join ReferenceDefs..vwCurrentTMC frc  
on tmc.TMC9ID=frc.TMC9ID -- frc.MvVersionID = lp.MvVersionID
where ProviderID != @providerid  

update #averagedSpeedsCompares  
set BiasOfOneProvider = a.AvgSpeed - b.AvgSpeed  
from #averagedSpeeds a, #averagedSpeedsCompares b  
where a.EdgeID = b.EdgeID  
and a.CaptureDtUTC = b.CaptureDtUTC  
and a.ProviderID = @providerid  
and b.ProviderID != @providerid  

--Find percent of speeds in range buckets compared to other providers
select '-10 to 10' RangeOfSpeed,
cast(round(count(case when BiasOfOneProvider between -10 and 10 then 1 end) * 100.0 / count(*),2) as numeric(36,2)) as PctPtsCompare
from #averagedSpeedsCompares
union all 
select '-15 to 15' RangeOfSpeed,
cast(round(count(case when BiasOfOneProvider between -15 and 15 then 1 end) * 100.0 / count(*),2) as numeric(36,2)) as PctPtsCompare
from #averagedSpeedsCompares
union all 
select '-20 to 20' RangeOfSpeed,
cast(round(count(case when BiasOfOneProvider between -20 and 20 then 1 end) * 100.0 / count(*),2) as numeric(36,2)) as PctPtsCompare
from #averagedSpeedsCompares

--produce usable output  
--speed bias by FRC or overall    
select replace(ProviderDesc,' real time','') as Provider, FRC, BiasOfOneProvider, count(1) as Count  
from #averagedSpeedsCompares s, ReferenceDefs..Provider p  
where s.ProviderID = p.ProviderID  
group by ProviderDesc, FRC, BiasOfOneProvider  
order by ProviderDesc, FRC, BiasOfOneProvider  
  
select replace(ProviderDesc,' real time','') as Provider, Color, BiasOfOneProvider, count(1) as Count  
from #averagedSpeedsCompares s, ReferenceDefs..Provider p  
where s.ProviderID = p.ProviderID  
group by ProviderDesc, Color, BiasOfOneProvider  
order by ProviderDesc, Color, BiasOfOneProvider  

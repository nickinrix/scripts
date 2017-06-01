/* Use any standard PIT database and change date range as needed */
drop table #pdata
drop table #sum_dup

select *
into #pdata
from PIT
where ArrivalDtUtc between '2017-01-17 19:00' and '2017-01-17 20:00' --select time range of interest

--query duplicates on following attributes filtering out counts > 1
select unitid, CaptureTimeUtc, count(*) as count_dup --Latitude, Longitude, Speed, Heading, 
into #sum_dup
from #pdata
--where speed <> 0 --filter non-moving vehicles/devices (not required, however non-moving vehicles can create duplicates)
group by unitid, CaptureTimeUtc --Latitude,Longitude,Speed,Heading,
having count(*) > 1

--query sum of duplicate total, total count, and duplicate % of total
;with A as
(
select sum(count_dup) as sum_dup
from #sum_dup
),
B as
(
select count(*) total_count from #pdata
)
select *, round((((cast(sum_dup as float) / cast(total_count as float))) * 100),2) as pct_dup from A, B


/* use to further investigate individual cases if needed */
--select * from #sum_dup

--select *
--from #pdata
--where UnitId = '495192405' and CaptureTimeUtc = '2017-03-07 16:10:29.000'


/* alternate queries to find duplicates for subfeeds */
--drop table #pdata
--drop table #sum_dup

--select CustomField01,analyticsvehicleid, CaptureDtUtc, count(*) as count_dup --Latitude, Longitude, Speed, Heading, 
--into #sum_dup
--from #pdata
----where speed <> 0 --filter non-moving vehicles/devices (not required, however non-moving vehicles can create duplicates)
--group by CustomField01, analyticsvehicleid, CaptureDtUtc --Latitude,Longitude,Speed,Heading,
--having count(*) > 1

----query sum of duplicate total, total count, and duplicate % of total
--;with A as
--(
--select CustomField01,sum(count_dup) as sum_dup
--from #sum_dup
--group by CustomField01
--),
--B as
--(
--select CustomField01, count(*) total_count from #pdata
--group by CustomField01
--)
--select *, round((((cast(sum_dup as float) / cast(total_count as float))) * 100),2) as pct_dup from A, B
--where A.CustomField01 = B.CustomField01
--order by A.CustomField01
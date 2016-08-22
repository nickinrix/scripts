--use script to find duplicates for any standard PIT database
drop table #pdata
drop table #sum_dup

select *
into #pdata
from PIT
where ArrivalDtUtc between '2016-06-17 19:00' and '2016-06-17 20:00' --select time range of interest

--query duplicates on following attributes filtering out counts > 1
select unitid, Latitude, Longitude, Speed, Heading, CaptureTimeUtc, count(*) as count_dup
into #sum_dup
from #pdata
where speed <> 0 --filter non-moving vehicles/devices (not required, however non-moving vehicles can create duplicates)
group by unitid, Latitude,Longitude,Speed,Heading,CaptureTimeUtc
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
select *, round((((cast(sum_dup as float) / cast(total_count as float))) * 100),0) as pct_dup from A, B


--use to further investigate individual cases if needed
--select *
--from #pdata
--where UnitId = '692703536' and CaptureTimeUtc = '2016-06-17 15:12:06.000'
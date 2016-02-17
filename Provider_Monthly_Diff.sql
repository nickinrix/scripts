--use WAFSQLBI01.BI
--sp_helptext [rptDustProviderMonthly_MDC]

with x as
(
select Provider as p1,  TotalPointsPIT as jan_vol
from dbo.AWS_MDC_DustProviderMonthly
where MonthStartDate = '2016-1-1'
),
y as
(
select Provider as p2, TotalPointsPIT as dec_vol
from dbo.AWS_MDC_DustProviderMonthly
where MonthStartDate = '2015-12-1'
)
select p1, p2, jan_vol, dec_vol, cast(jan_vol as float) - cast(dec_vol as float) as vol_diff
from x,y
where p1=p2
and cast(jan_vol as float) - cast(dec_vol as float) < -500000000
order by vol_diff desc
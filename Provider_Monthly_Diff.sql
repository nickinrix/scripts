--use WAFSQLBI01.BI and change start date as needed
--sp_helptext [rptDustProviderMonthly_MDC]

declare @currentmonthstartdate datetime
declare @previousmonthstartdate datetime

set @currentmonthstartdate = '2016-3-1'
set @previousmonthstartdate = '2016-2-1'

--select volume decreases greater than 500M for current month
;
with x as
(
select Provider as p1,  TotalPointsPIT as curr_vol
from dbo.AWS_MDC_DustProviderMonthly
where MonthStartDate = @currentmonthstartdate
),
y as
(
select Provider as provider, TotalPointsPIT as prev_vol
from dbo.AWS_MDC_DustProviderMonthly
where MonthStartDate = @previousmonthstartdate
)

select provider, replace(convert(varchar, cast(curr_vol as money), 1), '.00', '') as curr_vol, replace(convert(varchar, cast(prev_vol as money), 1), '.00', '') as prev_vol, replace(convert(varchar, cast(curr_vol as money) - cast(prev_vol as money), 1), '.00', '') as vol_diff
from x,y
where p1=provider
and cast(curr_vol as float) - cast(prev_vol as float) < -500000000
group by provider, curr_vol, prev_vol
order by vol_diff desc

--select volume percentage changes greater than 25%, and with total volume greater than 500K, for current month compared to previous month
;
with x as
(
select Provider as p1,  TotalPointsPIT as curr_vol
from dbo.AWS_MDC_DustProviderMonthly
where MonthStartDate = @currentmonthstartdate
),
y as
(
select Provider as provider, TotalPointsPIT as prev_vol
from dbo.AWS_MDC_DustProviderMonthly
where MonthStartDate = @previousmonthstartdate
)

select provider, replace(convert(varchar, cast(curr_vol as money), 1), '.00', '') as curr_vol, replace(convert(varchar, cast(prev_vol as money), 1), '.00', '') as prev_vol, round((((cast(curr_vol as float) / cast(prev_vol as float)) - 1) * 100),0) as pct_chg
from x,y
where p1=provider
and ((((cast(curr_vol as float) / cast(prev_vol as float)) - 1) * 100) >= 25 or (((cast(curr_vol as float) / cast(prev_vol as float)) - 1) * 100) <= -25)
and cast(curr_vol as float) > 500000
group by provider, curr_vol, prev_vol
order by 
    case IsNumeric(curr_vol) 
        when 1 then Replicate('0', 100 - Len(curr_vol)) + curr_vol
        else curr_vol
    end
	desc

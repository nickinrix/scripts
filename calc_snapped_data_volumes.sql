/* Use any DustFlowArchive database and change date range as needed */
drop table ##fdata

select *
into ##fdata
from FlowData
where [CaptureDtUtc] between '2017-5-10 00:00' and '2017-5-11 00:00'

select 
f.ProviderId
,p.providerDesc
--,f.ProcessGroupId
--,pg.ProcessGroupName
,c.Name as Country
,count(*) as data_count
,cast(count(distinct(sensorid)) as bigint) as unique_devices
from ##fdata f join referencedefs.dbo.processgroup pg on f.processgroupid  = pg.ProcessGroupID
join ReferenceDefs.dbo.CountryCode c on c.CountryCode = pg.CountryCode
join ReferenceDefs.dbo.provider p on f.providerid = p.providerid
--and providerId = 361
and f.ProcessGroupId in (
318
,323
)
group by f.ProviderId,p.providerDesc,c.Name --,f.ProcessGroupId ,ProcessGroupName
order by p.ProviderDesc

--select * from ReferenceDefs.dbo.ProcessGroup where processgroupname like '%sloven%'
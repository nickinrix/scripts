--Use CS PIT archive database DNFSQLARC04, select DB name, and change table name and date range as needed

DECLARE @dbName VARCHAR(20)
SET @dbName = (SELECT DB_NAME());
PRINT @dbName
  
declare @starttime datetime 
declare @endtime datetime     
declare @table nvarchar  

set @starttime = '2016-9-13 15:00'
set @endtime = '2016-9-13 15:15' 
set @table = 'PIT09'
  

drop table #pdata

--select data into temp table
select * 
into #pdata
from PIT09 
where ArrivalDtUtc between @starttime and @endtime


IF @dbName = 'CSPit_Mobile_Archive' 
	--select vendor ID from PIT, whitelist table, and production vendor name
	select p.VendorID as VendorIdPIT, ISNULL(vp.VendorID, -1) as VendorIdWhiteList, ISNULL(vp.[Description], -1) as VendorNmWhiteList, v1.VendorID as VendorIdDEN, v1.VendorName as VendorDEN
	, COUNT(*) as Volume
	from #pdata p 
	left outer join DNWMSQL02.ConnectedServicesPIT.dbo.vendorprovider vp on p.VendorID = vp.VendorID
	left outer join DNWMSQL03.inrixtrafficservice.dbo.vendor v1 on p.VendorID = v1.VendorId
	where (p.VendorID not in (12587, 12627, 12669, 12670)) --internal testing VendorIds  12502, 12512,  12605, 12627, 12632
	group by p.VendorID, vp.VendorID, vp.[Description], v1.VendorID, v1.VendorName
	order by VendorIdWhiteList, Volume desc
ELSE
	--select vendor ID from PIT, whitelist table, and production vendor name
	select p.VendorID as VendorIdPIT, ISNULL(vp.VendorID, -1) as VendorIdWhiteList, ISNULL(vp.[Description], -1) as VendorNmWhiteList, v1.VendorID as VendorIdDEN, v1.VendorName as VendorDEN
	, COUNT(*) as Volume
	from #pdata p 
	left outer join DNWSQL03.ConnectedServicesPIT.dbo.vendorprovider vp on p.VendorID = vp.VendorID
	left outer join DNWSQL05.[InrixTrafficService].dbo.vendor v1 on p.VendorID = v1.VendorId 
	where (p.VendorID not in (12587, 12627, 12669, 12670)) --internal testing VendorIds  12502, 12512,  12605, 12627, 12632
	group by p.VendorID, vp.VendorID, vp.[Description], v1.VendorID, v1.VendorName
	order by VendorIdWhiteList, Volume desc

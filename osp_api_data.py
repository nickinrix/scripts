from __future__ import print_function
from collections import Counter
import requests
import datetime as dt
from dateutil import tz
from xml.etree import ElementTree as ET
import pyodbc
import pandas.io.sql as psql
import pandas as pd
import os
import threading as td
import time

def get_local_time(timestamp):
    from_zone = tz.gettz('UTC')
    to_zone = tz.gettz('America/New_York')
    timestamp2 = timestamp.replace(tzinfo=from_zone)
    return timestamp2.astimezone(to_zone)

MarketID = int(raw_input('What MarketID are you interested in?'))

cnxn_string ='DRIVER={SQL Server};SERVER=WSBSQL12;DATABASE=OSParkingDefs;UID=trafficdbo;PWD=Fastlane_405!'

cnxn = pyodbc.connect(cnxn_string) 
cursor = cnxn.cursor()
sql ="SELECT * FROM [OSParkingDefs].[dbo].[OSParkingMarket] where MarketID =" + str(MarketID)

osp_market = psql.read_sql(sql, cnxn)
cnxn.close()
osp_market

tokenResponse = requests.get('http://na-api.beta.inrix.com/Traffic/Inrix.ashx?action=getsecuritytoken&VendorId=1271404893&ConsumerId=beee2087-9fc1-49ae-87ab-6cffcc8b2247').content
tokenRoot = ET.fromstring(tokenResponse)
token = tokenRoot.find('.//AuthResponse//AuthToken').text
print (token)

name = osp_market['MarketName']
c1lat = str(osp_market['Corner1Latitude'].values[0]) #'40.734551'
c1lon = str(osp_market['Corner1Longitude'].values[0]) #'-73.989921'
c2lat = str(osp_market['Corner2Latitude'].values[0]) #'40.718891'
c2lon = str(osp_market['Corner2Longitude'].values[0]) #'-73.974922'

dirpath = ('c:\\temp\\') #enter to desired local path
if not os.path.exists(dirpath):
    os.makedirs(dirpath)


file_name = 'osp_sea_api_test.csv' #configure file name
newfilepath = (dirpath + file_name)
with open(newfilepath, 'wb') as new_file:
        new_file.write((',').join(['time_stamp','blockID','block_side','sum_capacity','occupancy','bucket','source','ioccupancy','ifprobability','iprobability','idprobability','irtprobability','rtprobability','polyline']))
        new_file.write('\n')
        new_file.close()

lot_file = 'lots_sea_api_test.csv' #configure file name
new_lot_file_path = (dirpath + lot_file)
with open(new_lot_file_path, 'wb') as new_lot_file:
        new_lot_file.write((',').join(['time_stamp','lotID','latitude','longitude','name','capacity','occupancy','available']))
        new_lot_file.write('\n')
        new_lot_file.close()


start_time = dt.datetime.utcnow() # dt.datetime.strptime('2016-07-04T00:00:00.0Z', '%Y-%m-%dT%H:%M:%S.%fZ') #enter specific time
current_time = start_time
while current_time < start_time+dt.timedelta(hours=96): 
    time_stamp = dt.datetime.strftime(current_time, '%Y-%m-%dT%H:%M:%S.%fZ')     
    parking_api = 'http://na-api.beta.inrix.com/Traffic/Inrix.ashx?action=GetParkingInfoInBox' +\
        '&corner1=' + c1lat + '|' + c1lon + '&corner2=' + c2lat + '|' + c2lon + '&locale=en-US&type=parkingblocks,parkingspots,parkinglots&' + \
        'token=' + token + '&compress=true' + '&outputFields=all,debugdynamic' #+ '&arrivalTime=' + time_stamp
    #print (parking_api)
    data = requests.get(parking_api).content
    xml_data = ET.fromstring(data)
    data_list = []
    
    for block in xml_data.iterfind('ParkingBlocks/ParkingBlock'):
        blockID = block.get('id')
        polyline = block.find('StaticContent/Geometry/Polyline').text
        #print (blockID)
        #break
        l_source = ''
        l_data = ''
        l_sum_capacity = 0
        l_bucket_list = [0]
        l_occupancy_list = [0]
        l_ioccupancy_list = [0]
        l_ifprobability_list = [0]
        l_iprobability_list = [0]
        l_idprobability_list = [0]
        l_irtprobability_list = [0]
        l_rtprobability_list = [0]

        r_source = ''
        r_data = ''
        r_sum_capacity = 0
        r_bucket_list = [0]
        r_occupancy_list = [0]
        r_ioccupancy_list = [0]
        r_ifprobability_list = [0]
        r_iprobability_list = [0]
        r_idprobability_list = [0]
        r_irtprobability_list = [0]
        r_rtprobability_list = [0]
        #for each side of road
        #    sum capacity for for each side of the road
        #    get bucket and occupancy from <Occupancy bucket="1">23</Occupancy> if Dynamic content exists for the block/side
        # use get_local_time(current_time) to output the day/time buckets in local time
        for section in block.iterfind('ParkingSections/ParkingSection'):
            side = section.find('Side').text
            if side == 'Left':
                l_side = side
                if section.find('StaticContent/ParkingCapacity') is not None:
                    l_capacity = int(section.find('StaticContent/ParkingCapacity').text)

                    if l_capacity > 0 and section.find('DynamicContent') is not None:
                        l_occupancy_list.append(int(section.find('DynamicContent/Occupancy').text))   
                        l_bucket_list.append(int(section.find('DynamicContent/Occupancy').get('bucket')))  
                        l_source = section.find('DynamicContent/Occupancy').get('source')

                        if section.find('DynamicContent/IOccupancy') is None:
                            l_ioccupancy_list == 0
                        else:
                            l_ioccupancy_list.append(int(section.find('DynamicContent/IOccupancy').text))  

                        if section.find('DynamicContent/IFProbability') is None:
                            l_ifprobability_list == 0
                        else:
                            l_ifprobability_list.append(int(section.find('DynamicContent/IFProbability').text))  

                        if section.find('DynamicContent/IProbability') is None:
                            l_iprobability_list == 0
                        else:
                            l_iprobability_list.append(int(section.find('DynamicContent/IProbability').text))  

                        if section.find('DynamicContent/IDProbability') is None:
                            l_idprobability_list == 0
                        else:
                            l_idprobability_list.append(int(section.find('DynamicContent/IDProbability').text))  

                        if section.find('DynamicContent/IRTProbability') is None:
                            l_irtprobability_list == 0
                        else:
                            l_irtprobability_list.append(int(section.find('DynamicContent/IRTProbability').text))  

                        if section.find('DynamicContent/RTProbability') is None:
                            l_rtprobability_list == 0
                        else:
                            l_rtprobability_list.append(int(section.find('DynamicContent/RTProbability').text))  

                    l_sum_capacity += (l_capacity)

                l_bucket = max(l_bucket_list)
                l_occupancy = max(l_occupancy_list)   
                l_ioccupancy = max(l_ioccupancy_list)
                l_ifprobability = max(l_ifprobability_list)
                l_iprobability = max(l_iprobability_list)
                l_idprobability = max(l_idprobability_list)
                l_irtprobability = max(l_irtprobability_list)
                l_rtprobability = max(l_rtprobability_list)

                l_data = (time_stamp,blockID,l_side,l_sum_capacity,l_occupancy,l_bucket,l_source,l_ioccupancy,l_ifprobability,l_iprobability,l_idprobability,l_irtprobability,l_rtprobability,polyline)  
            elif side == 'Right':
                r_side = side
                if section.find('StaticContent/ParkingCapacity') is not None:
                    r_capacity = int(section.find('StaticContent/ParkingCapacity').text)

                    if r_capacity > 0 and section.find('DynamicContent') is not None:
                        r_occupancy_list.append(int(section.find('DynamicContent/Occupancy').text))
                        r_bucket_list.append(int(section.find('DynamicContent/Occupancy').get('bucket')))
                        r_source = section.find('DynamicContent/Occupancy').get('source')

                        if section.find('DynamicContent/IOccupancy') is None:
                            r_ioccupancy_list == 0
                        else:
                            r_ioccupancy_list.append(int(section.find('DynamicContent/IOccupancy').text))  

                        if section.find('DynamicContent/IFProbability') is None:
                            r_ifprobability_list == 0
                        else:
                            r_ifprobability_list.append(int(section.find('DynamicContent/IFProbability').text))  

                        if section.find('DynamicContent/IProbability') is None:
                            r_iprobability_list == 0
                        else:
                            r_iprobability_list.append(int(section.find('DynamicContent/IProbability').text))  

                        if section.find('DynamicContent/IDProbability') is None:
                            r_idprobability_list == 0
                        else:
                            r_idprobability_list.append(int(section.find('DynamicContent/IDProbability').text))  

                        if section.find('DynamicContent/IRTProbability') is None:
                            r_irtprobability_list == 0
                        else:
                            r_irtprobability_list.append(int(section.find('DynamicContent/IRTProbability').text))  

                        if section.find('DynamicContent/RTProbability') is None:
                            r_rtprobability_list == 0
                        else:
                            r_rtprobability_list.append(int(section.find('DynamicContent/RTProbability').text))  

                    r_sum_capacity += (r_capacity)                    

                r_bucket = max(r_bucket_list)
                r_occupancy = max(r_occupancy_list)
                r_ioccupancy = max(r_ioccupancy_list)
                r_ifprobability = max(r_ifprobability_list)
                r_iprobability = max(r_iprobability_list)
                r_idprobability = max(r_idprobability_list)
                r_irtprobability = max(r_irtprobability_list)
                r_rtprobability = max(r_rtprobability_list)

                r_data = (time_stamp,blockID,r_side,r_sum_capacity,r_occupancy,r_bucket,r_source,r_ioccupancy,r_ifprobability,r_iprobability,r_idprobability,r_irtprobability,r_rtprobability,polyline)
                    
        #append data to list
        data_list.append(l_data)
        data_list.append(r_data)
        dup_list = list(set(data_list))
    #create dataframe from list and save results to csv
    columns = ('time_stamp','blockID','block_side','sum_capacity','occupancy','bucket','source','ioccupancy','ifprobability','iprobability','idprobability','irtprobability','rtprobability','polyline')

    all_data_df = pd.DataFrame.from_records(dup_list,columns=columns)

    all_data_df.to_csv(newfilepath, index=False, mode='a', chunksize=10000, header=False)

    #lot data
    lot_data_list = []
    
    for lot in xml_data.iterfind('ParkingLots/ParkingLot'):
        lot_data = ''
        lot_capacity = ''
        lot_occupancy = ''
        lot_available = ''
        
        lotID = lot.get('id')
        #print (lotID)
        #break
        lat = lot.get('latitude')
        lon = lot.get('longitude')
        name = lot.get('name')
        
        if lot.find('staticContent') is not None:
            lot_capacity = int(lot.find('staticContent/description/parkingSpecification').get('capacity'))
        if lot.find('dynamicContent') is not None:
            lot_occupancy = int(lot.find('dynamicContent/currentCapacity').get('parkingOccupancyPercentage'))
            lot_available = int(lot.find('dynamicContent/currentCapacity').get('availableSpaces'))

        lot_data = (time_stamp,lotID,lat,lon,name,lot_capacity,lot_occupancy,lot_available)
                    
        #append data to list
        lot_data_list.append(lot_data)

    #create dataframe from list and save results to csv
    columns = ('time_stamp','lotID','latitude','longitude','name','capacity','occupancy','available')

    lot_data_df = pd.DataFrame.from_records(lot_data_list,columns=columns)

    lot_data_df.to_csv(new_lot_file_path, index=False, mode='a', chunksize=10000, header=False)

    print ('parsing data at ' + time_stamp + ' from API complete')
    time.sleep(1800)
    current_time = dt.datetime.utcnow() #current_time + dt.timedelta(minutes=60)

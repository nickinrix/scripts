import pandas as pd #data and analysis module
import os

# Global month start date values
value = '2015-3-1'
month_str = '2016'

# Create a Pandas Excel writer using XlsxWriter as the engine.
excel_writer = pd.ExcelWriter("C:\\temp\\Provider Reporting - %s.xlsx" % month_str, engine='xlsxwriter')

def adodbapi_connection(server, database, username, password):

    import adodbapi
    connectors = ["Provider=SQLOLEDB"]
    connectors.append("Data Source=%s" % server)
    connectors.append("Initial Catalog=%s" % database)
    connectors.append("User Id=%s" % username)
    connectors.append("Password=%s" % password)
    return adodbapi.connect(";".join(connectors))

#Dust Provider Report - MDC
dust_report_conn = adodbapi_connection('WAFSQLBI01', 'BI', 'trafficdbo', 'Fastlane_405!')
dust_report_df = pd.read_sql("EXEC rptDustProviderMonthly_MDC '%s'" % value, con = dust_report_conn)
dust_report_df.to_excel(excel_writer,sheet_name='Dust MDC',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Dust MDC']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})
header_format = workbook.add_format({'bold': True,
                                     'align': 'center',
                                     'valign': 'vcenter',
                                     'fg_color': 'grey',
                                     'border': 1})

# Set the column width and format.
worksheet.set_column('B:B', 28, None)
worksheet.set_column('C:C', 18, None)
worksheet.set_column('D:M', 60, number_format)
worksheet.freeze_panes(1,0)
#for col in range(0, 9):
#worksheet.write(0, header_format)	

#Dust Provider Report CH
dust_report_ch_conn = adodbapi_connection('BEFSQLARC01', 'BI', 'trafficdbo', 'goKART_108!')
dust_report_ch_df = pd.read_sql("EXEC rptDustProviderMonthly '%s'" % value, con = dust_report_ch_conn)
dust_report_ch_df.to_excel(excel_writer,sheet_name='Dust China',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Dust China']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('B:B', 28, None)
worksheet.set_column('C:C', 18, None)
worksheet.set_column('D:X', 60, number_format)

#CS PIT Vendor Points Report
vendor_report_conn = adodbapi_connection('DNFSQLARC04', 'MDR_Host', 'trafficdbo', 'Fastlane_405!')
vendor_report_df = pd.read_sql("EXEC rptCSPitVendorCountsMDC '%s'" % value, con = vendor_report_conn)
vendor_report_df.to_excel(excel_writer,sheet_name='CS Vendors',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['CS Vendors']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('B:B', 20, None)
worksheet.set_column('C:C', 48, None)
worksheet.set_column('D:X', 15, number_format)
worksheet.freeze_panes(1,0)

#QC Units for Finance - MDC (QC=Qualcomm aka Omnitracs)
qc_units_report_conn = adodbapi_connection('WAFSQLBI01', 'BI', 'trafficdbo', 'Fastlane_405!')
qc_units_report_df = pd.read_sql("EXEC rptQualCommMonthlyUnitsReport '%s'" % value, con = qc_units_report_conn)
qc_units_report_df.to_excel(excel_writer,sheet_name='Omnitracs for Finance',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Omnitracs for Finance']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('A:A', 18, None)
worksheet.set_column('B:B', 15, number_format)

#Sensor Provider Report
sensor_report_conn = adodbapi_connection('WAFSQLBI01', 'BI', 'trafficdbo', 'Fastlane_405!')
sensor_report_df = pd.read_sql("EXEC rptSensorProviderMetricsByMonth '%s'" % value, con = sensor_report_conn)
sensor_report_df.to_excel(excel_writer,sheet_name='Sensors',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Sensors']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('B:B', 35, None)
worksheet.set_column('C:C', 18, None)
worksheet.set_column('D:E', 20, number_format)

#Travel Time Provider Report
travel_time_report_conn = adodbapi_connection('DNFSQLARC06', 'FlowArchive', 'trafficdbo', 'Fastlane_405!')
travel_time_report_df = pd.read_sql("EXEC rptOpsDailyFlowStats '%s'" % value, con = travel_time_report_conn)
travel_time_report_df.to_excel(excel_writer,sheet_name='Travel Time',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Travel Time']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('A:A', 28, None)
worksheet.set_column('B:B', 18, None)
worksheet.set_column('C:C', 15, number_format)

#User Generated Incident Summary Report
ugi_report_conn = adodbapi_connection('WSSQL02', 'UGIncident', 'trafficdbo', 'Fastlane_405!')
ugi_report_df = pd.read_sql("EXEC spOpsUGIncidentSummaryRpt '%s'" % value, con = ugi_report_conn)
ugi_report_df.to_excel(excel_writer,sheet_name='User Generated Incidents',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['User Generated Incidents']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11'})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('B:C', 18, None)
worksheet.set_column('D:E', 15, number_format)

#Flow Summary for Bryan - MDC
flow_summary_report_conn = adodbapi_connection('WAFSQLBI01', 'BI', 'trafficdbo', 'Fastlane_405!')
flow_summary_report_df = pd.read_sql("EXEC spFlowSummaryRpt_MDC_TTX3 '%s'" % value, con = flow_summary_report_conn)
flow_summary_report_df.to_excel(excel_writer,sheet_name='Flow for Bryan',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Flow for Bryan']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###','font_size': '11','bold': True})
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('A:A', 28, None)
worksheet.set_column('B:B', 10, None)
worksheet.set_column('D:E', 18, None)
worksheet.write('A200','Total', number_format)
worksheet.write_formula('D200','{=SUM(D1:D199)}', number_format)
worksheet.write_formula('E200','{=SUM(E1:E199)}', number_format)
worksheet.freeze_panes(1,0)
workbook.close()
excel_writer.save

print("Report generation complete")

#Send final report
#os.system('C:\\temp\\blat\\blat.exe -install 10.1.1.21 mbbatch@inrix.com 10 25')
#os.system('C:\\temp\\blat\\blat.exe "C:\\temp\\Provider Reporting - %s.xlsx" -from mbbatch@inrix.com -to nick@inrix.com -subject "Provider Reporting Test" -body "All, attached is the report.  Totals are located on the Flow for Bryan tab.  Thank you." ' % month_str)
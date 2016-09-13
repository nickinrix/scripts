import pandas as pd #data and analysis module
import os
import numpy as np
import matplotlib.pyplot as plt

# Global month start date values
value = '2015-10-01'
date_str = 'September 12 2016'

# Create a Pandas Excel writer using XlsxWriter as the engine.
excel_writer = pd.ExcelWriter("C:\\temp\\Provider Daily Stats - %s.xlsx" % date_str, engine='xlsxwriter')

def adodbapi_connection(server, database, username, password):

    import adodbapi
    connectors = ["Provider=SQLOLEDB"]
    connectors.append("Data Source=%s" % server)
    connectors.append("Initial Catalog=%s" % database)
    connectors.append("User Id=%s" % username)
    connectors.append("Password=%s" % password)
    return adodbapi.connect(";".join(connectors))

summary_report_conn = adodbapi_connection('DNDMTARC01', 'DMT_DataMonitoring', 'trafficdbo', 'Fastlane_405!')
summary_report_df = pd.read_sql("SELECT * FROM dbo.PITCountMonitorReport_v2 where DateUTC >= '%s'" % value, con =summary_report_conn)
summary_report_df.to_excel(excel_writer,sheet_name='Daily Stats',index = False)

# Get the xlsxwriter objects from the dataframe writer object.
workbook  = excel_writer.book
worksheet = excel_writer.sheets['Daily Stats']

# Add some cell formats.
number_format = workbook.add_format({'num_format': '###,###,###,###'}) #,'font_size': '8'
percent_format = workbook.add_format({'num_format': '0%'})
time_format = workbook.add_format({'num_format': 'h:mm:ss AM/PM'})

# Set the column width and format.
worksheet.set_column('A:A', 30, None)
worksheet.set_column('B:B', 10, None)
worksheet.set_column('C:C', 15, None)
worksheet.set_column('D:F', 15, number_format)
worksheet.set_column('G:H', 15, percent_format)
worksheet.set_column('I:L', 20, None)
worksheet.freeze_panes(1,0)
workbook.close()
excel_writer.save

print("Report generation complete")

#providerdata = summary_report_df.set_index(['DateUTC'])
#providerdata = pd.DataFrame(providerdata,columns=['LivePITRows','ProviderName'])
summary_report_df = summary_report_df.query('ProviderName == ["arvento","cdcom","autoguard","lbslocal"]') #,"flitsmeister","mapquest","telenav","navmii","qualcomm","sygic","ctrack"
#summary_report_df['total'] = summary_report_df.LivePITRows
providerdata = pd.pivot_table(summary_report_df,index=['DateUTC'],aggfunc=np.sum,values=['LivePITRows'],columns=['ProviderName'])#

ax = providerdata.plot(kind='line',figsize=(20, 10))#,stacked=True,
ax.set_ylabel('Count (millions)')
ax.legend(loc=2)
plt.style.use('ggplot')
plt.gcf().autofmt_xdate()
#print plt.style.available
#plt.show()
plt.gcf().savefig('C:\\temp\\dailyproviderstats.jpg')
plt.close()
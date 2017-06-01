import boto
import pandas as pd
import numpy as np
import bz2
import glob
import sys,os
import fnmatch

access_key = '' #enter S3 access key
secret_key = '' #enter S3 secret key
dirpath = ('c:\\temp\\') #enter to desired local path
if not os.path.exists(dirpath):
    os.makedirs(dirpath)

#create connection to S3
conn = boto.connect_s3(
        aws_access_key_id = access_key,
        aws_secret_access_key = secret_key,
        #host = 'objects.dreamhost.com',
        #is_secure=False,               # uncomment if you are not using ssl
        #calling_format = boto.s3.connection.OrdinaryCallingFormat(),
        )

#from the connection list all files (keys) available for the selected bucket
bucket = conn.get_bucket('inrixprod-pit')

#copy selected file(s) from bucket to local directory
k = bucket.list(prefix='.inputawsupload-staging-daily/year=2016/month=02/day=02/')
for x in k:
    try:
        if x.key.endswith('informap.bz2'):
            basename = os.path.basename(x.name.split('/')[-1])
            path = os.path.join(dirpath, "%s" % basename)
            x.get_contents_to_filename(path)
            print "wrote %s" % path
    except:
        print (x.key +":"+"FAILED")

#decompress the selected file(s) on local directory
for f in os.listdir(dirpath):
    if fnmatch.fnmatch(f, '*.informap.bz2'):
        zipfile = bz2.BZ2File(dirpath + f) # open the file
        data = zipfile.read() # get the decompressed data
        newfilepath = (dirpath + f + '.decompressed') # assuming the filepath ends with .bz2
        with open(newfilepath, 'wb') as new_file:
            new_file.write(data)# write a uncompressed file
        print "decompressed %s" % f
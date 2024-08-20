import boto3
s3 = boto3.resource('s3')

s3.create_bucket(Bucket='myron-zion-zoran', CreateBucketConfiguration={
    'LocationConstraint': 'ap-south-1'})

# Boto3
s3.Object('mybucket', 'hello.txt').put(Body=open('/tmp/hello.txt', 'rb'))
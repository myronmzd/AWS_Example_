import boto3
import os

# Initialize the S3 resource
s3 = boto3.resource('s3')

# Create an S3 bucket
bucket_name = 'myron-zion-zoran'
region = 'ap-south-1'

try:
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={'LocationConstraint': region}
    )
    print(f"Bucket '{bucket_name}' created successfully.")
except Exception as e:
    print(f"Error creating bucket: {e}")

# File content and path
file_content = "Hello, this is a test file."
file_path = '/tmp/hello.txt'

# Create the file
try:
    with open(file_path, 'w') as file:
        file.write(file_content)
    print(f"File '{file_path}' created successfully.")
except Exception as e:
    print(f"Error creating file: {e}")

# Ensure the file exists before uploading
if os.path.exists(file_path):
    try:
        # Upload the file to S3
        with open(file_path, 'rb') as file_data:
            s3.Object(bucket_name, 'hello.txt').put(Body=file_data)
        print("File uploaded successfully.")
    except Exception as e:
        print(f"Error uploading file: {e}")
else:
    print(f"File '{file_path}' does not exist.")
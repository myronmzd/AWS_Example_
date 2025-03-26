import json
import boto3
import os

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print("Event:", json.dumps(event, indent=2))
    
    # Extract S3 event from SNS message
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    s3_event = sns_message['Records'][0]
    
    input_bucket = s3_event['s3']['bucket']['name']
    object_key = s3_event['s3']['object']['key']
    
    output_bucket = os.environ['OUTPUT_BUCKET']
    
    copy_source = {'Bucket': input_bucket, 'Key': object_key}
    target_key = object_key  # Copy with the same name
    
    s3.copy_object(Bucket=output_bucket, Key=target_key, CopySource=copy_source)
    
    return {
        "statusCode": 200,
        "body": f"File copied from {input_bucket}/{object_key} to {output_bucket}/{target_key}"
    }

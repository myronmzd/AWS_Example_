import boto3
import os

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    
    # Get the source bucket and object key from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']
    
    # Get the destination bucket from environment variables
    destination_bucket = os.environ['OUTPUT_BUCKET']
    
    # Copy the object to the destination bucket
    try:
        s3_client.copy_object(
            Bucket=destination_bucket,
            Key=source_key,
            CopySource={'Bucket': source_bucket, 'Key': source_key}
        )
        
        return {
            'statusCode': 200,
            'body': f'Successfully copied {source_key} to {destination_bucket}'
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        raise e

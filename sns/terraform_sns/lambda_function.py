import boto3
import os
import json
from datetime import datetime

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    sns = boto3.client('sns')
    
    # Get the source bucket and object key from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']
    file_size = event['Records'][0]['s3']['object']['size']
    event_time = event['Records'][0]['eventTime']

    
    # Get the destination bucket from environment variables
    destination_bucket = os.environ['OUTPUT_BUCKET']
    
    try:
        # Copy the object to the destination bucket
        s3_client.copy_object(
            Bucket=destination_bucket,
            Key=source_key,
            CopySource={'Bucket': source_bucket, 'Key': source_key}
        )

        # Convert size to MB for better readability
        size_mb = file_size / (1024 * 1024)
        
        # Create a readable timestamp
        timestamp = datetime.strptime(event_time, '%Y-%m-%dT%H:%M:%S.%fZ')
        formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S')
        
        # For the destination bucket URL, we'll use the region where the Lambda is running
        # since that's typically the same region as the destination bucket
        lambda_region = os.environ['AWS_REGION']  # This is automatically available in Lambda


        # Construct the S3 HTTPS URL
        s3_url = f"https://{destination_bucket}.s3.{lambda_region}.amazonaws.com/{source_key}"


        # Customize your message
        message = f"""
        ✅ File Processing Complete!
        
        File Details:
        -------------
        📁 File Name: {source_key}
        📊 File Size: {size_mb:.2f} MB
        ⏰ Processed Time: {formatted_time}
        📂 Source Bucket: {source_bucket}
        📂 Destination Bucket: {destination_bucket}
        

        📎 File URL: {s3_url}
        The file has been successfully copied to the destination bucket.
        """
        
        # Send the notification
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"File Copy Complete: {source_key}",
            Message=message
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps('File copied and notification sent successfully')
        }
        
    except Exception as e:
        error_message = f"Error: {str(e)}"
        print(error_message)
        raise e

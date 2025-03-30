import boto3
from botocore.exceptions import ClientError
import logging

logger = logging.getLogger(__name__)

def send_sqs_message(queue_url, message_body, message_attributes=None):
    """
    Send a message to an SQS queue
    
    Parameters:
    queue_url (string): URL of existing SQS queue
    message_body (string): Message to be sent
    message_attributes (dict): Optional message attributes
    
    Returns:
    dict: MessageId if message is sent, None otherwise
    """
    sqs_client = boto3.client('sqs')
    
    try:
        if not message_attributes:
            message_attributes = {}
            
        response = sqs_client.send_message(
            QueueUrl=queue_url,
            MessageBody=message_body,
            MessageAttributes=message_attributes
        )
        return response['MessageId']
        
    except ClientError as error:
        logger.error(f"Failed to send message: {error}")
        raise error

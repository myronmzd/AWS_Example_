# Amazon SNS (Simple Notification Service)

This repository contains AWS SAM templates and example code for working with Amazon Simple Notification Service (SNS), a fully managed pub/sub messaging service that enables you to decouple microservices, distributed systems, and serverless applications.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Deployment](#deployment)
  - [Testing](#testing)
- [Project Structure](#project-structure)
- [SNS Topics](#sns-topics)
- [Message Publishing](#message-publishing)
- [Subscriptions](#subscriptions)
- [Message Filtering](#message-filtering)
- [Security](#security)
- [Monitoring](#monitoring)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Related Resources](#related-resources)

## Features

- **Pub/Sub Messaging**: Decouple and scale microservices, distributed systems, and serverless applications
- **Multiple Protocols**: Deliver messages via HTTP/S, Email, SMS, Mobile Push, and Lambda
- **Fan-Out**: Send messages to multiple subscribers in parallel
- **Message Filtering**: Filter messages so subscribers only receive relevant messages
- **Serverless**: No infrastructure to manage, scales automatically with your workload
- **Durability**: Messages are stored redundantly across multiple availability zones
- **Security**: Encryption at rest and in transit, fine-grained access control with IAM

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      SNS Architecture                       │
│  ┌─────────────────┐     ┌─────────────────┐              │
│  │  Publishers     │     │  Subscribers     │              │
│  │  (Producers)    │     │  (Consumers)     │              │
│  └────────┬────────┘     └────────┬────────┘              │
│           │                        │                        │
│  ┌────────▼────────────────────────▼────────┐              │
│  │              SNS Topic                   │              │
│  │  ┌─────────────────────────────────────┐  │              │
│  │  │  Message Routing & Filtering        │  │              │
│  │  └───────────────────┬─────────────────┘  │              │
│  └─────────────────────┼─────────────────────┘              │
│                       │                                      │
│  ┌───────────────────┴─────────────────┐                  │
│  │  Delivery Protocols                 │                  │
│  │  ┌───────┐  ┌───────┐  ┌─────────┐  │                  │
│  │  │  HTTP │  │ Email │  │  Lambda │  │                  │
│  │  └───────┘  └───────┘  └─────────┘  │                  │
│  └──────────────────────────────────────┘                  │
└───────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- AWS SAM CLI [installed](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Node.js 14.x+ or Python 3.8+ (for Lambda functions)

## Getting Started

### Deployment

1. **Build the application**
   ```bash
   sam build --use-container
   ```

2. **Deploy the application**
   ```bash
   sam deploy --guided
   ```
   
   Follow the interactive prompts to configure your deployment.

3. **Verify the deployment**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name sns-application \
     --query 'Stacks[0].Outputs[?OutputKey==`SNSTopicArn`].OutputValue' \
     --output text
   ```

### Testing

1. **Publish a test message**
   ```bash
   aws sns publish \
     --topic-arn <YOUR_TOPIC_ARN> \
     --subject "Test Message" \
     --message "Hello from SNS!"
   ```

2. **Check CloudWatch Logs**
   ```bash
   sam logs --stack-name sns-application --tail
   ```

## Project Structure

```
sns/
├── template.yml            # SAM template defining SNS topics and subscriptions
├── src/                    # Lambda function code
│   ├── app.py              # Python Lambda handler
│   ├── requirements.txt    # Python dependencies
│   └── index.js            # Node.js Lambda handler
├── events/                 # Test events
│   └── event.json          # Sample SNS event
└── README.md               # This file
```

## SNS Topics

### Create a Topic

```yaml
Resources:
  MyTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: my-topic
      DisplayName: My SNS Topic
      Tags:
        - Key: Environment
          Value: Production
```

### Topic with Server-Side Encryption

```yaml
  EncryptedTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: encrypted-topic
      KmsMasterKeyId: alias/aws/sns  # Or your custom KMS key
      Tags:
        - Key: Environment
          Value: Production
```

## Message Publishing

### Publish to a Topic (CLI)

```bash
aws sns publish \
  --topic-arn arn:aws:sns:region:account-id:my-topic \
  --subject "Important Notification" \
  --message "This is a test message" \
  --message-attributes '{"priority":{"DataType":"String","StringValue":"high"}}'
```

### Publish from Lambda (Python)

```python
import boto3

def lambda_handler(event, context):
    sns = boto3.client('sns')
    
    response = sns.publish(
        TopicArn='arn:aws:sns:region:account-id:my-topic',
        Subject='Lambda Notification',
        Message='This message was sent from Lambda',
        MessageAttributes={
            'environment': {
                'DataType': 'String',
                'StringValue': 'production'
            }
        }
    )
    
    return {
        'statusCode': 200,
        'body': 'Message published successfully!'
    }
```

## Subscriptions

### Email Subscription

```yaml
  EmailSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: email
      Endpoint: user@example.com
      TopicArn: !Ref MyTopic
```

### Lambda Subscription

```yaml
  LambdaSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: lambda
      Endpoint: !GetAtt MyLambdaFunction.Arn
      TopicArn: !Ref MyTopic
```

### SQS Subscription with Filter Policy

```yaml
  SQSSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: sqs
      Endpoint: !GetAtt MyQueue.Arn
      TopicArn: !Ref MyTopic
      FilterPolicy:
        store: ["example_corp"]
        price_usd: [{"numeric": [">=", 100]}]  # Only messages with price >= 100
```

## Message Filtering

### Attribute-based Filtering

```json
{
  "store": ["example_corp"],
  "event": ["order_placed"],
  "customer_interests": ["soccer", "rugby", "hockey"],
  "price_usd": [{"numeric": [">=", 100]}]  // Only messages with price >= 100
}
```

### Multiple Filter Policies

```yaml
Resources:
  HighPrioritySubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: email
      Endpoint: admin@example.com
      TopicArn: !Ref MyTopic
      FilterPolicy:
        priority: ["high", "urgent"]

  AllMessagesSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Protocol: email
      Endpoint: all@example.com
      TopicArn: !Ref MyTopic
      FilterPolicy: {}
```

## Security

### Topic Policy

```yaml
  TopicPolicy:
    Type: AWS::SNS::TopicPolicy
    Properties:
      Topics:
        - !Ref MyTopic
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              AWS: "*"
            Action: "sns:Publish"
            Resource: !Ref MyTopic
            Condition:
              StringEquals:
                aws:SourceVpc: vpc-12345678
```

### Data Protection with KMS

```yaml
  KMSKey:
    Type: AWS::KMS::Key
    Properties:
      KeyPolicy:
        Version: '2012-10-17'
        Id: key-default-1
        Statement:
          - Sid: Enable IAM User Permissions
            Effect: Allow
            Principal: 
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'

  EncryptedTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: secure-topic
      KmsMasterKeyId: !Ref KMSKey
```

## Monitoring

### CloudWatch Alarms

```yaml
  SNSAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmDescription: "Alarm when there are more than 100 failed notifications in 5 minutes"
      Namespace: AWS/SNS
      MetricName: NumberOfNotificationsFailed
      Dimensions:
        - Name: TopicName
          Value: !Select [1, !Split [":", !Select [5, !Split ["-", !Ref MyTopic]]]]
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 100
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref AlarmTopic
```

### CloudWatch Logs for Delivery Status

```yaml
  DeliveryStatusLogging:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: delivery-status-topic
      Subscription:
        - Protocol: lambda
          Endpoint: !GetAtt DeliveryStatusFunction.Arn
```

## Cost Optimization

### Message Compression

For large messages, compress the payload before publishing:

```python
import gzip
import json
import base64

def publish_compressed_message(topic_arn, message):
    sns = boto3.client('sns')
    
    # Compress the message
    compressed = gzip.compress(json.dumps(message).encode('utf-8'))
    
    # Encode in base64 for SNS
    encoded = base64.b64encode(compressed).decode('utf-8')
    
    # Publish with compression flag
    response = sns.publish(
        TopicArn=topic_arn,
        Subject='Compressed Message',
        Message=encoded,
        MessageAttributes={
            'compression': {
                'DataType': 'String',
                'StringValue': 'gzip+base64'
            }
        }
    )
    
    return response
```

### Batch Processing

For high-throughput scenarios, batch messages where possible:

```python
def publish_batch_messages(topic_arn, messages, batch_size=10):
    sns = boto3.client('sns')
    
    for i in range(0, len(messages), batch_size):
        batch = messages[i:i + batch_size]
        
        # Publish each message in the batch
        for message in batch:
            sns.publish(
                TopicArn=topic_arn,
                Message=json.dumps(message),
                MessageStructure='json'
            )
```

## Troubleshooting

### Common Issues

1. **Message Delivery Failures**
   - Check CloudWatch Logs for delivery attempts
   - Verify subscription status with `aws sns list-subscriptions-by-topic`
   - Check if the endpoint has sufficient permissions to receive messages

2. **Message Filtering Not Working**
   - Verify the filter policy syntax is valid JSON
   - Check if the message attributes match the filter policy
   - Ensure the filter policy is properly attached to the subscription

3. **High Latency**
   - Check if the topic is in the same region as the subscribers
   - Monitor the `Publish` and `NumberOfNotificationsDelivered` metrics
   - Consider using FIFO topics for strict ordering and deduplication

## Cleanup

To avoid ongoing charges, delete the CloudFormation stack when done:

```bash
aws cloudformation delete-stack --stack-name sns-application
```

Or delete individual resources:

```bash
# Delete a topic
aws sns delete-topic --topic-arn arn:aws:sns:region:account-id:my-topic

# Remove a subscription
aws sns unsubscribe --subscription-arn arn:aws:sns:region:account-id:my-topic:subscription-id
```

## Related Resources

- [Amazon SNS Documentation](https://docs.aws.amazon.com/sns/)
- [SNS Best Practices](https://docs.aws.amazon.com/sns/latest/dg/sns-best-practices.html)
- [Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)
- [SNS with Lambda](https://docs.aws.amazon.com/lambda/latest/dg/with-sns.html)
- [SNS CloudFormation Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_SNS.html)

---

*Note: Always follow the principle of least privilege when configuring IAM policies for SNS. Use message filtering to ensure subscribers only receive relevant messages, reducing unnecessary processing and costs.*
# Amazon SQS Basic Example

This repository contains a basic implementation of Amazon Simple Queue Service (SQS) using AWS CloudFormation. The template creates an SQS queue and configures an SNS topic for operational alerts.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Deployment](#deployment)
  - [Sending Messages](#sending-messages)
  - [Receiving Messages](#receiving-messages)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Cleanup](#cleanup)
- [Related Resources](#related-resources)

## Features

- Creates a standard SQS queue
- Configures an SNS topic for operational alerts
- Email notifications for operational issues
- CloudFormation outputs for easy integration

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      SQS Architecture                       │
│  ┌─────────────────┐               ┌─────────────────┐    │
│  │  Producers      │               │  Consumers      │    │
│  │  (Senders)      │               │  (Receivers)    │    │
│  └────────┬────────┘               └────────┬────────┘    │
│           │                                    │             │
│  ┌────────▼────────────────────────────────┐   │             │
│  │          Amazon SQS Queue              │   │             │
│  │  ┌───────────────────────────────────┐  │   │             │
│  │  │  Message Storage & Management     │  │   │             │
│  │  └───────────────────┬───────────────┘  │   │             │
│  └─────────────────────┼───────────────────┘   │             │
│                       │                         │             │
│  ┌───────────────────┴───────────────────┐   ┌┴────────┐   │
│  │  SNS Topic for Alerts               │   │  Email   │   │
│  │  • Operational notifications        │   │  Alerts  │   │
│  └────────────────────────────────────┘   └──────────┘   │
└───────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- Basic understanding of AWS CloudFormation
- IAM permissions to create and manage SQS and SNS resources

## Getting Started

### Deployment

1. **Deploy the CloudFormation stack**:
   ```bash
   ./deploy.sh
   ```
   This will create an SQS queue and an SNS topic for alerts.

2. **Verify the deployment**:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name sqs-basic-queue \
     --query 'Stacks[0].Outputs[?OutputKey==`QueueURL`].OutputValue' \
     --output text
   ```

### Sending Messages

1. **Send a test message**:
   ```bash
   ./send.sh "Your test message"
   ```

2. **Send a message with AWS CLI**:
   ```bash
   QUEUE_URL=$(aws cloudformation describe-stacks \
     --stack-name sqs-basic-queue \
     --query 'Stacks[0].Outputs[?OutputKey==`QueueURL`].OutputValue' \
     --output text)
   
   aws sqs send-message \
     --queue-url $QUEUE_URL \
     --message-body "Hello from AWS CLI" \
     --message-attributes '{"Priority":{"StringValue":"High","DataType":"String"}}'
   ```

### Receiving Messages

1. **Receive messages**:
   ```bash
   ./receive.sh
   ```

2. **Receive messages with AWS CLI**:
   ```bash
   QUEUE_URL=$(aws cloudformation describe-stacks \
     --stack-name sqs-basic-queue \
     --query 'Stacks[0].Outputs[?OutputKey==`QueueURL`].OutputValue' \
     --output text)
   
   # Receive messages
   RESPONSE=$(aws sqs receive-message \
     --queue-url $QUEUE_URL \
     --attribute-names All \
     --message-attribute-names All \
     --max-number-of-messages 10 \
     --visibility-timeout 30 \
     --wait-time-seconds 20)
   
   # Display messages
   echo "$RESPONSE" | jq -r '.Messages[] | .Body'
   
   # Delete messages after processing
   echo "$RESPONSE" | jq -r '.Messages[] | .ReceiptHandle' | while read handle; do
     aws sqs delete-message \
       --queue-url $QUEUE_URL \
       --receipt-handle "$handle"
   done
   ```

## Project Structure

```
sqs/basic/
├── README.md           # This file
├── deploy.sh           # Script to deploy the CloudFormation stack
├── message.json        # Example message payload
├── receive.sh          # Script to receive messages from the queue
├── send.sh             # Script to send messages to the queue
└── template.yaml       # CloudFormation template for the SQS queue
```

## Configuration

The CloudFormation template includes the following resources:

1. **SQS Queue**:
   - Queue name: SampleQueue
   - Default settings for visibility timeout and message retention

2. **SNS Topic**:
   - Email subscription for operational alerts
   - Configurable email address parameter

## Monitoring

### View Queue Metrics

```bash
QUEUE_NAME="SampleQueue"

# Get approximate number of messages in queue
aws cloudwatch get-metric-statistics \
  --namespace AWS/SQS \
  --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=$QUEUE_NAME \
  --start-time $(date -v-1H -u +"%Y-%m-%dT%H:%M:%S") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%S") \
  --period 300 \
  --statistics Average \
  --output json
```

### Set Up CloudWatch Alarms

```bash
QUEUE_ARN=$(aws sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

aws cloudwatch put-metric-alarm \
  --alarm-name "HighMessageCount-$QUEUE_NAME" \
  --alarm-description "Alarm when messages in queue > 1000 for 5 minutes" \
  --namespace AWS/SQS \
  --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=$QUEUE_NAME \
  --statistic Average \
  --period 300 \
  --threshold 1000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions $ALARM_TOPIC_ARN
```

## Cleanup

To avoid ongoing charges, delete the CloudFormation stack when done:

```bash
aws cloudformation delete-stack --stack-name sqs-basic-queue
```

## Related Resources

- [Amazon SQS Documentation](https://docs.aws.amazon.com/sqs/)
- [SQS Best Practices](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-best-practices.html)
- [SQS with CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html)
- [SQS CLI Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sqs/index.html)

---

*Note: Always follow the principle of least privilege when configuring IAM policies for SQS. Monitor your queues and set up appropriate alarms to ensure smooth operation of your messaging system.*

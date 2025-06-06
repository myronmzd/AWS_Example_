# Amazon DynamoDB Examples

This repository contains examples and resources for working with Amazon DynamoDB, a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Deployment](#deployment)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Related Resources](#related-resources)

## Features

- **Fully Managed**: No servers to manage, no software to install
- **Scalability**: Seamless scaling to handle any amount of traffic
- **Performance**: Single-digit millisecond latency at any scale
- **Flexible Data Model**: Key-value and document data model support
- **Built-in Security**: Encryption at rest and in transit
- **Global Tables**: Multi-region, multi-master database
- **Backup and Restore**: Point-in-time recovery and on-demand backups
- **Time to Live (TTL)**: Automatic item expiration

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- AWS SDK (if using programmatic access)
- Basic understanding of NoSQL database concepts

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/AWS_Example_.git
   cd "AWS_Example_/DynamoDB Basics"
   ```

2. **Install dependencies** (if any)
   ```bash
   # Example for Node.js projects
   npm install
   ```

## Project Structure

```
DynamoDB Basics/
├── bin/
│   └── template.yaml       # CloudFormation template
├── src/
│   ├── create-table.js    # Example: Create table
│   ├── crud-operations.js # CRUD operations
│   └── queries.js         # Query examples
├── test/                  # Test files
└── README.md              # This file
```

## Deployment

### Using AWS CloudFormation

Deploy the DynamoDB table using the provided CloudFormation template:

```bash
aws cloudformation deploy \
  --template-file bin/template.yaml \
  --stack-name my-dynamodb-stack \
  --capabilities CAPABILITY_IAM
```

### Verify Deployment

Check the CloudFormation stack status:
```bash
aws cloudformation describe-stacks --stack-name my-dynamodb-stack
```

## Examples

### Basic Operations

#### Create a Table
```javascript
// Using AWS SDK for JavaScript
const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB();

const params = {
  TableName: 'MyTable',
  KeySchema: [
    { AttributeName: 'id', KeyType: 'HASH' },
    { AttributeName: 'timestamp', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'id', AttributeType: 'S' },
    { AttributeName: 'timestamp', AttributeType: 'N' }
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 5,
    WriteCapacityUnits: 5
  }
};

dynamoDB.createTable(params, (err, data) => {
  if (err) console.error('Error:', err);
  else console.log('Table created:', data);
});
```

#### CRUD Operations

```javascript
// Add an item
const params = {
  TableName: 'MyTable',
  Item: {
    'id': { S: 'user1' },
    'name': { S: 'John Doe' },
    'email': { S: 'john@example.com' },
    'timestamp': { N: Date.now().toString() }
  }
};

dynamoDB.putItem(params, (err, data) => {
  if (err) console.error('Error:', err);
  else console.log('Item added:', data);
});
```

## Best Practices

### Data Modeling
- Design for single-table design when possible
- Use composite keys for flexible access patterns
- Consider access patterns during design
- Use sparse indexes for efficient queries

### Performance
- Use DynamoDB Accelerator (DAX) for read-heavy workloads
- Implement exponential backoff for throttling
- Use batch operations for multiple items
- Consider using DynamoDB Streams for change data capture

### Security
- Use IAM roles and policies for access control
- Enable encryption at rest
- Use VPC endpoints for private access
- Implement fine-grained access control with IAM conditions

## Monitoring and Maintenance

### CloudWatch Metrics
- Monitor `ConsumedReadCapacityUnits` and `ConsumedWriteCapacityUnits`
- Set alarms for `ThrottledRequests`
- Track `UserErrors` and `SystemErrors`

### Maintenance Tasks
- Update indexes as access patterns change
- Review and adjust capacity units based on usage
- Regularly back up important tables
- Monitor and optimize query performance

## Troubleshooting

### Common Issues
1. **ProvisionedThroughputExceededException**
   - Implement exponential backoff
   - Consider increasing provisioned capacity
   - Review access patterns and optimize queries

2. **ValidationException**
   - Verify attribute types match the schema
   - Check for required attributes
   - Ensure data types match the expected format

3. **ResourceNotFoundException**
   - Verify table name and region
   - Check if table exists
   - Confirm IAM permissions

## Security

- **Encryption**: Enable encryption at rest using AWS KMS
- **Access Control**: Use IAM policies to control access
- **VPC Endpoints**: Use VPC endpoints for private network access
- **Audit Logging**: Enable AWS CloudTrail for API call logging

## Cost Optimization

- Use on-demand capacity for unpredictable workloads
- Implement auto-scaling for predictable workloads
- Delete unused tables and indexes
- Use time-to-live (TTL) to expire old items
- Consider using DynamoDB Standard-IA for infrequently accessed data

## Related Resources

- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [AWS CLI DynamoDB Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/dynamodb/index.html)
- [DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/)
# Amazon S3 (Simple Storage Service)

This repository contains resources, scripts, and best practices for working with Amazon S3, a scalable object storage service that offers industry-leading scalability, data availability, security, and performance.

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Basic Commands](#basic-commands)
  - [S3 Sync Script](#s3-sync-script)
  - [S3 Operations](#s3-operations)
- [Best Practices](#best-practices)
- [Security](#security)
- [Monitoring](#monitoring)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Related Resources](#related-resources)

## Features

- **Object Storage**: Store and retrieve any amount of data
- **Scalability**: Virtually unlimited storage capacity
- **Durability & Availability**: 99.999999999% (11 nines) durability
- **Security**: Encryption, access control, and compliance capabilities
- **Versioning**: Keep multiple versions of an object
- **Lifecycle Management**: Automate moving objects to cost-effective storage classes
- **Static Website Hosting**: Host static websites directly from S3
- **Event Notifications**: Trigger AWS Lambda, SQS, or SNS on object changes

## Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- IAM user with S3 permissions

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-repo/AWS_Example_.git
   cd AWS_Example_/S3
   ```

2. Make the scripts executable:
   ```bash
   chmod +x bash-scripts/sys
   ```

## Usage

### Basic Commands

#### List Buckets
```bash
aws s3 ls
```

#### Create a Bucket
```bash
aws s3 mb s3://your-bucket-name --region us-west-2
```

#### Copy Files to S3
```bash
aws s3 cp local-file.txt s3://your-bucket-name/
```

#### Sync Directory to S3
```bash
aws s3 sync ./local-directory s3://your-bucket-name/remote-directory
```

### S3 Sync Script

The provided `bash-scripts/sys` script simplifies syncing local files to an S3 bucket:

```bash
./bash-scripts/sys <bucket-name> <folder-name>
```

Example:
```bash
./bash-scripts/sys my-awesome-bucket my-folder
```

### S3 Operations

#### Enable Versioning
```bash
aws s3api put-bucket-versioning \
  --bucket your-bucket-name \
  --versioning-configuration Status=Enabled
```

#### Set Bucket Policy
```bash
cat > bucket-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
EOL

aws s3api put-bucket-policy \
  --bucket your-bucket-name \
  --policy file://bucket-policy.json
```

#### Enable Static Website Hosting
```bash
aws s3 website s3://your-bucket-name/ --index-document index.html --error-document error.html
```

## Best Practices

### Naming Conventions
- Use DNS-compliant bucket names (lowercase, no underscores)
- Include environment prefixes (dev-, prod-, etc.)
- Be consistent across your organization

### Data Organization
- Use meaningful prefixes/folders
- Implement lifecycle policies for data archival
- Enable versioning for critical data
- Use object tagging for better management

### Performance
- Use multipart upload for large files (>100MB)
- Enable transfer acceleration for faster uploads
- Use byte-range fetches for partial file access
- Optimize request patterns to avoid request rate limitations

## Security

### Encryption
- Enable default encryption for all new objects
- Use AWS KMS for customer-managed keys
- Implement bucket policies to enforce encryption in transit (HTTPS)

### Access Control
- Follow the principle of least privilege
- Use IAM roles for EC2 instances
- Implement S3 Block Public Access
- Regularly audit S3 bucket policies and ACLs

### Logging and Monitoring
- Enable server access logging
- Use AWS CloudTrail for API activity logging
- Set up CloudWatch Alarms for suspicious activity

## Monitoring

### CloudWatch Metrics
- Monitor `BucketSizeBytes` and `NumberOfObjects`
- Track `4xxErrorCount` and `5xxErrorCount`
- Set up alerts for unusual activity

### S3 Storage Lens
- Enable S3 Storage Lens for organization-wide visibility
- Analyze storage usage and access patterns
- Identify cost optimization opportunities

## Cost Optimization

### Storage Classes
- Use S3 Standard for frequently accessed data
- Move infrequently accessed data to S3 Standard-IA or S3 One Zone-IA
- Archive data to S3 Glacier or S3 Glacier Deep Archive for long-term storage

### Lifecycle Policies
```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket your-bucket-name \
  --lifecycle-configuration file://lifecycle.json
```

Example `lifecycle.json`:
```json
{
  "Rules": [
    {
      "ID": "Move to Glacier after 30 days",
      "Status": "Enabled",
      "Prefix": "archive/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Verify IAM permissions
   - Check bucket policies and ACLs
   - Ensure the bucket is in the correct region

2. **Slow Uploads/Downloads**
   - Check network connectivity
   - Consider using S3 Transfer Acceleration
   - Verify if you're hitting request rate limits

3. **Versioning Conflicts**
   - Check if versioning is enabled
   - Verify object version IDs
   - Check for delete markers

## Related Resources

- [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS CLI S3 Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/index.html)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)

---

*Note: Always follow the principle of least privilege when configuring S3 permissions and regularly audit your S3 resources for security best practices.*
# AWS S3 to SNS Notification System

## Overview
This project implements an automated notification system using AWS S3 and SNS. When files are uploaded to an S3 bucket, the system processes them and sends formatted email notifications via SNS.

## Architecture
```
Input Bucket → Lambda → Output Bucket → SNS → Email Notification
```

## Features
- Automated file processing notifications
- Formatted email alerts
- Secure file handling
- Real-time processing updates

## Prerequisites
- AWS Account
- Terraform >= 0.12
- AWS CLI configured
- Python 3.8+

## Resources Created
- S3 Input Bucket
- S3 Output Bucket  
- SNS Topic
- Email Subscription
- IAM Roles & Policies

## Quick Setup
### 1. Clone the repository
```bash
git clone <repository-url>
cd terraform_sns
```

### 2. Update variables in `terraform.tfvars`:
```hcl
input_bucket_name  = "XXXXXXXXXXXXXXX"
output_bucket_name = "XXXXXXXXXXXXXXXX"
email_endpoint     = "your-email@example.com"
```

### 3. Initialize and apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

### 4. Confirm SNS subscription via email

## Usage
1. Upload a file to the input bucket.
2. System processes the file to the output bucket.
3. Receive a formatted email notification:

```
📋 File Processing Notification

✅ Status: Successfully Processed
📁 File Name: example.csv
📊 File Size: 1.5 MB
⏰ Completed: March 28, 2024 at 02:30 PM

🔗 Access Your File:
https://bucket-name.s3.region.amazonaws.com/example.csv
```

### Email Tested
![image](https://github.com/user-attachments/assets/e4b21140-1786-46f9-9018-804013c16137)

## Configuration
Key variables in `variables.tf`:
```hcl
variable "input_bucket_name" {
  description = "Name of the input S3 bucket"
  type        = string
}

variable "output_bucket_name" {
  description = "Name of the output S3 bucket"
  type        = string
}

variable "email_endpoint" {
  description = "Email address for notifications"
  type        = string
}
```

## Clean Up
Remove all resources:
```bash
terraform destroy
```

## Troubleshooting
### Common issues:
#### No Email Notifications
- Check email subscription confirmation.
- Verify SNS topic policy.

#### Processing Failures
- Check Lambda CloudWatch logs.
- Verify IAM permissions.

## Security
- S3 buckets encrypted at rest.
- Least privilege IAM policies.
- Secure Lambda execution.

## Contributing
1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.

## License
MIT License


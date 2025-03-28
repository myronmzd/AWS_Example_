# AWS S3 to SNS Notification System

## Overview
This project implements an automated notification system using AWS S3 and SNS. When files are uploaded to an S3 bucket, the system processes them and sends formatted email notifications via SNS.

## Architecture

Copy

Insert at cursor
markdown
Input Bucket → Lambda → Output Bucket → SNS → Email Notification


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
1. Clone the repository
```bash
git clone <repository-url>
cd terraform_sns

Copy

Insert at cursor
text
Update variables in terraform.tfvars:

input_bucket_name  = "XXXXXXXXXXXXXXX"
output_bucket_name = "XXXXXXXXXXXXXXXX"
email_endpoint     = "your-email@example.com"

Copy

Insert at cursor
hcl
Initialize and apply Terraform:

terraform init
terraform plan
terraform apply

Copy

Insert at cursor
bash
Confirm SNS subscription via email

Usage
Upload a file to the input bucket

System processes the file to output bucket

Receive formatted email notification:

📋 File Processing Notification

✅ Status: Successfully Processed
📁 File Name: example.csv
📊 File Size: 1.5 MB
⏰ Completed: March 28, 2024 at 02:30 PM

🔗 Access Your File:
https://bucket-name.s3.region.amazonaws.com/example.csv


Email tested 
![image](https://github.com/user-attachments/assets/e4b21140-1786-46f9-9018-804013c16137)

Copy

Insert at cursor
text
Configuration
Key variables in variables.tf:

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

Copy

Insert at cursor
hcl
Clean Up
Remove all resources:

terraform destroy

Copy

Insert at cursor
bash
Troubleshooting
Common issues:

No Email Notifications

Check email subscription confirmation

Verify SNS topic policy

Processing Failures

Check Lambda CloudWatch logs

Verify IAM permissions

Security
S3 buckets encrypted at rest

Least privilege IAM policies

Secure Lambda execution

Contributing
Fork the repository

Create feature branch

Submit pull request

License
MIT License


# AWS Auto Scaling Group (ASG) Deployment

This repository contains a comprehensive solution for deploying an AWS Auto Scaling Group using AWS CloudFormation. The infrastructure as code (IaC) approach ensures consistent and repeatable deployments of scalable and highly available applications on AWS.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [Infrastructure Details](#infrastructure-details)
- [Scaling](#scaling)
- [Monitoring](#monitoring)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Cost Considerations](#cost-considerations)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                           │
│  ┌─────────────┐     ┌─────────────────┐                  │
│  │  Internet   │     │  Application    │                  │
│  │  Gateway    │     │  Load Balancer  │                  │
│  └──────┬──────┘     └────────┬────────┘                  │
│         │                      │                            │
│         │                      │                            │
│  ┌──────▼──────┐     ┌────────▼────────┐                  │
│  │  NAT        │     │  Public Subnet  │                  │
│  │  Gateway    │     │  (AZ A & B)     │                  │
│  └──────┬──────┘     └────────┬────────┘                  │
│         │                      │                            │
│  ┌──────▼──────┐     ┌────────▼────────┐     ┌─────────────┐│
│  │  Private    │     │  Auto Scaling   │     │  CloudWatch  ││
│  │  Subnet     │     │  Group          │     │  Alarms      ││
│  │  (AZ A & B) │     │                 │     │             ││
│  └─────────────┘     └─────────────────┘     └─────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Features

- **High Availability**: Deploys instances across multiple Availability Zones
- **Auto Scaling**: Automatically adjusts the number of EC2 instances based on demand
- **Load Balancing**: Distributes traffic across multiple instances
- **Self-Healing**: Automatically replaces unhealthy instances
- **Security**: Implements security best practices with security groups and IAM roles
- **Infrastructure as Code**: Uses AWS CloudFormation for reliable and repeatable deployments

## Prerequisites

- **AWS Account**: Active AWS account with appropriate permissions
- **AWS CLI**: [Install and configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) the AWS Command Line Interface
- **Key Pair**: An existing EC2 Key Pair in the target AWS region
- **IAM Permissions**: User must have permissions to create and manage:
  - EC2 instances and related resources
  - Auto Scaling Groups
  - Elastic Load Balancers
  - IAM roles and policies
  - CloudWatch Alarms and Logs

## Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/AWS_Example_.git
cd AWS_Example_/asg
```

### 2. Make the Deployment Script Executable

```bash
chmod +x deploy.sh
```

### 3. Run the Deployment Script

```bash
./deploy.sh
```

### 4. Verify the Deployment

After the deployment completes, you can verify the resources in the AWS Management Console:
- **EC2 Console**: Check the running instances
- **EC2 Auto Scaling Console**: Verify the Auto Scaling Group
- **EC2 Load Balancer Console**: Check the load balancer and target groups
- **CloudFormation Console**: Review the stack resources and events

## Infrastructure Details

The CloudFormation template (`template.yaml`) creates the following resources:

### Networking
- **VPC**: A virtual private cloud with a specified CIDR block
- **Subnets**: Public and private subnets across multiple Availability Zones
- **Internet Gateway**: Enables internet access for resources in public subnets
- **Route Tables**: Configured routes for public and private subnets
- **NAT Gateway**: Allows instances in private subnets to access the internet

### Security
- **Security Groups**:
  - Web Server Security Group: Allows HTTP/HTTPS traffic from the internet
  - Load Balancer Security Group: Controls traffic to the load balancer
  - Instance Security Group: Controls traffic to the EC2 instances
- **IAM Roles**:
  - EC2 Instance Role: Grants permissions to EC2 instances
  - Auto Scaling Service Role: Allows Auto Scaling to manage AWS resources

### Compute
- **Launch Template**: Defines the EC2 instance configuration
  - AMI ID: Latest Amazon Linux 2 AMI
  - Instance Type: Configurable (default: t3.micro)
  - Storage: EBS volumes with encryption
  - User Data: Bootstrap script for instance configuration

### Load Balancing
- **Application Load Balancer (ALB)**: Distributes traffic across instances
- **Target Groups**: Routes requests to registered targets (EC2 instances)
- **Listeners**: Configures HTTP/HTTPS listeners for the load balancer

### Auto Scaling
- **Auto Scaling Group**: Manages the EC2 instances
  - Desired Capacity: Initial number of instances
  - Minimum Size: Minimum number of instances
  - Maximum Size: Maximum number of instances
  - Health Check Type: ELB health checks
  - Health Check Grace Period: Time to allow instances to boot
- **Scaling Policies**:
  - Target Tracking Policy: Scale based on CPU utilization
  - Step Scaling Policies: Scale based on custom CloudWatch metrics

## Scaling

The Auto Scaling Group is configured with the following scaling policies:

### Target Tracking Scaling
- **CPU Utilization**: Scale to maintain 70% CPU utilization
- **Request Count**: Scale based on the number of requests per target

### Step Scaling
- **Scale Out**: Add instances when CPU utilization > 75% for 5 minutes
- **Scale In**: Remove instances when CPU utilization < 25% for 15 minutes

### Scheduled Scaling
- **Business Hours**: Increase desired capacity during business hours
- **Non-Business Hours**: Decrease desired capacity during off-hours

## Monitoring

### CloudWatch Alarms
- **High CPU Utilization**: Triggered when CPU > 80% for 5 minutes
- **Low CPU Utilization**: Triggered when CPU < 20% for 15 minutes
- **ELB 5xx Errors**: Triggered when HTTP 5xx errors exceed threshold
- **ELB Target Response Time**: Triggered when response time exceeds threshold

### CloudWatch Logs
- **System Logs**: EC2 system logs
- **Application Logs**: Application-specific logs
- **Access Logs**: ALB access logs

## Cleanup

To avoid incurring charges, delete the CloudFormation stack when you no longer need it:

```bash
aws cloudformation delete-stack --stack-name MyASGStack --region us-west-2
```

## Troubleshooting

### Common Issues
1. **Stack Creation Fails**
   - Check the CloudFormation events for errors
   - Verify that the IAM user has sufficient permissions
   - Ensure the specified Key Pair exists in the region

2. **Instances Not Joining the Target Group**
   - Check the instance status in the EC2 console
   - Verify the security group allows traffic from the load balancer
   - Check the instance system logs for errors

3. **Auto Scaling Not Working**
   - Verify the CloudWatch alarms are in the ALARM state
   - Check the Auto Scaling activity history
   - Ensure the scaling policies are properly configured

## Security

- **Encryption**: All EBS volumes are encrypted
- **Least Privilege**: IAM roles follow the principle of least privilege
- **Security Groups**: Restrict access to only necessary ports and protocols
- **SSH Access**: SSH access is restricted to your IP address

## Cost Considerations

- **EC2 Instances**: t3.micro instances are eligible for the AWS Free Tier
- **Load Balancer**: Charges apply for each hour the load balancer is running
- **Data Transfer**: Data transfer costs apply for traffic to/from the internet
- **NAT Gateway**: Hourly charges apply for each NAT Gateway

For detailed pricing, refer to the [AWS Pricing Calculator](https://calculator.aws/).

- **VPC**: A Virtual Private Cloud with DNS support and hostnames enabled.
- **Subnets**: Two public subnets in different availability zones.
- **Internet Gateway**: An Internet Gateway attached to the VPC.
- **Route Table**: A route table with a default route to the Internet Gateway.
- **Security Groups**: Security groups for the Load Balancer and EC2 instances.
- **Load Balancer**: An Application Load Balancer with a listener and target group.
- **Launch Template**: A launch template for EC2 instances with user data to install and start a web server.
- **Auto Scaling Group**: An Auto Scaling Group with a scaling policy based on CPU utilization.

## Monitoring

The script monitors the CloudFormation stack status and provides updates on resource creation progress.

## License

This project is licensed under the MIT License.
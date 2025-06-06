# Amazon EC2 (Elastic Compute Cloud)

This repository contains CloudFormation templates and scripts for working with Amazon EC2, providing scalable compute capacity in the AWS Cloud.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Using CloudFormation](#using-cloudformation)
  - [Using AWS CLI Script](#using-aws-cli-script)
- [Project Structure](#project-structure)
- [EC2 Instance Types](#ec2-instance-types)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup & Recovery](#backup--recovery)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Related Resources](#related-resources)

## Features

- **Elastic Compute**: Resizable compute capacity in the cloud
- **Multiple Instance Types**: Choose from a variety of instance types optimized for different use cases
- **Security**: Built-in security features including IAM roles, security groups, and key pairs
- **Elastic IP Addresses**: Static IPv4 addresses for dynamic cloud computing
- **Elastic Block Store (EBS)**: Persistent block storage volumes for your instances
- **Auto Scaling**: Automatically scale your instances based on demand
- **Load Balancing**: Distribute incoming traffic across multiple instances
- **Multiple Operating Systems**: Choose from Amazon Linux, Ubuntu, Windows, and more

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        EC2 Architecture                    │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                      EC2 Instance                   │  │
│  │  ┌─────────────┐     ┌─────────────────┐           │  │
│  │  │  Instance   │     │  EBS Volume     │           │  │
│  │  │  Store      │     │  (Optional)     │           │  │
│  │  └─────┬───────┘     └────────┬────────┘           │  │
│  │        │                       │                     │  │
│  │  ┌─────▼───────┐     ┌────────▼────────┐           │  │
│  │  │  Metadata   │     │  Security       │           │  │
│  │  │  Service    │     │  Group          │           │  │
│  │  └────────────┘     └─────────────────┘           │  │
│  └──────────┬────────────────────────┬────────────────┘  │
│             │                        │                   │
│  ┌──────────▼─────────┐    ┌────────▼──────────┐        │
│  │  Elastic IP        │    │  Key Pair         │        │
│  │  (Optional)        │    │                   │        │
│  └────────────────────┘    └───────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- Key pair for SSH access (or create one using the provided script)
- Basic understanding of networking concepts (VPC, subnets, security groups)

## Getting Started

### Using CloudFormation

1. **Deploy the EC2 stack**
   ```bash
   aws cloudformation deploy \
     --template-file "simple Ec2 SSH/template.yaml" \
     --stack-name my-ec2-stack \
     --capabilities CAPABILITY_IAM
   ```

2. **Monitor the stack creation**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name my-ec2-stack \
     --query 'Stacks[0].StackStatus'
   ```

3. **Get the instance public IP**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name my-ec2-stack \
     --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIp`].OutputValue' \
     --output text
   ```

### Using AWS CLI Script

1. **Make the script executable**
   ```bash
   chmod +x "simple Ec2 SSH/templete.sh"
   ```

2. **Run the EC2 creation script**
   ```bash
   ./"simple Ec2 SSH/templete.sh"
   ```

## Project Structure

```
Ec2/
└── simple Ec2 SSH/
    ├── Readme.md         # This file
    ├── keypair.sh        # Script to create a key pair
    ├── mata_data.sh      # Script to retrieve instance metadata
    ├── template.yaml     # CloudFormation template
    └── templete.sh       # Bash script to create EC2 instance
```

## EC2 Instance Types

| Type           | Use Case                           | Example Instances     |
|----------------|-----------------------------------|----------------------|
| General Purpose| Balanced compute, memory, networking| t3, m5, m6i         |
| Compute Optimized| Compute-intensive applications   | c5, c6g, c6i        |
| Memory Optimized| Memory-intensive workloads        | r5, r6g, x2gd       |
| Storage Optimized| High-performance databases        | i3, i4g, d3en       |
| Accelerated Computing| Machine learning, graphics    | p4, g5, inf1       |


## Security

### Key Pairs

```bash
# Create a new key pair
aws ec2 create-key-pair \
  --key-name MyKeyPair \
  --key-type rsa \
  --key-format pem \
  --query 'KeyMaterial' \
  --output text > MyKeyPair.pem

# Set proper permissions
chmod 400 MyKeyPair.pem
```

### Security Groups

```yaml
  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable SSH access
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: <YOUR_IP_ADDRESS>/32
```

### IAM Roles

```yaml
  EC2InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: /
      Roles:
        - !Ref EC2Role

  EC2Role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: [ec2.amazonaws.com]
            Action: ['sts:AssumeRole']
      Path: /
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

## Monitoring

### CloudWatch Metrics

```bash
# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time $(date -d "1 hour ago" -u +"%Y-%m-%dT%H:%M:%S") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%S") \
  --period 300 \
  --statistics Average
```

### CloudWatch Alarms

```yaml
  HighCPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmDescription: "Alarm when CPU exceeds 80%"
      MetricName: CPUUtilization
      Namespace: AWS/EC2
      Statistic: Average
      Period: 300
      EvaluationPeriods: 1
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: InstanceId
          Value: !Ref EC2Instance
```

## Backup & Recovery

### EBS Snapshots

```bash
# Create a snapshot
aws ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "Daily backup $(date +%Y-%m-%d)"

# Create an AMI from an instance
aws ec2 create-image \
  --instance-id i-1234567890abcdef0 \
  --name "MyServer-$(date +%Y-%m-%d)" \
  --description "AMI created on $(date)" \
  --no-reboot
```

## Cost Optimization

### Instance Scheduling

```yaml
  EC2Scheduler:
    Type: AWS::Events::Rule
    Properties:
      Description: "Stop EC2 instances at night"
      ScheduleExpression: "cron(0 0 * * ? *)"
      State: ENABLED
      Targets:
        - Arn: !GetAtt StopEC2Function.Arn
          Id: StopEC2Target
```

### Spot Instances

```yaml
  EC2SpotInstance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t3.micro
      ImageId: ami-0c55b159cbfafe1f0
      InstanceMarketOptions:
        MarketType: spot
        SpotOptions:
          MaxPrice: "0.05"
          SpotInstanceType: one-time
```

## Troubleshooting

### Common Issues

1. **SSH Connection Refused**
   - Verify security group allows SSH (port 22) from your IP
   - Check if the instance has a public IP
   - Verify the key pair is correct and has proper permissions (400)
   - Check system logs in the EC2 console

2. **Instance Status Checks Failed**
   - Check EC2 status checks in the AWS Console
   - Review system and instance logs
   - Consider stopping and starting the instance

3. **High CPU or Memory Usage**
   - Use CloudWatch metrics to identify the issue
   - Connect using Session Manager and run `top` or `htop`
   - Consider upgrading the instance type if needed

## Cleanup

To avoid ongoing charges, delete the CloudFormation stack when done:

```bash
aws cloudformation delete-stack --stack-name my-ec2-stack
```

Or delete individual resources:

```bash
# Terminate an instance
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Delete a key pair
aws ec2 delete-key-pair --key-name MyKeyPair
```

## Related Resources

- [Amazon EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [EC2 Spot Instances](https://aws.amazon.com/ec2/spot/)
- [AWS CloudFormation EC2 Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_EC2.html)

---

*Note: Always follow the principle of least privilege when configuring IAM roles and security groups. Regularly backup your instances using EBS snapshots or AMIs.*
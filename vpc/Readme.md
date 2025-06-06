
# Amazon Virtual Private Cloud (VPC)

This repository contains resources, CloudFormation templates, and scripts for working with Amazon Virtual Private Cloud (VPC), enabling you to launch AWS resources in a logically isolated virtual network.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Using CloudFormation](#using-cloudformation)
  - [Using AWS CLI](#using-aws-cli)
- [Project Structure](#project-structure)
- [VPC Components](#vpc-components)
- [Security](#security)
- [Monitoring](#monitoring)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Related Resources](#related-resources)

## Features

- **Fully Isolated Network**: Create logically isolated sections of the AWS Cloud
- **Custom IP Address Range**: Define your own IP address range in CIDR format
- **Subnet Configuration**: Public, private, and isolated subnets across multiple Availability Zones
- **Internet Connectivity**: Internet Gateway for public subnets
- **Private Connectivity**: NAT Gateway/Instance for outbound internet access from private subnets
- **Network Access Control**: Security Groups and Network ACLs for layered security
- **VPC Peering**: Connect VPCs with other AWS accounts or within the same account
- **VPC Endpoints**: Privately connect to AWS services without using public IPs
- **Flow Logs**: Capture information about IP traffic going to and from network interfaces

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC Architecture                     │
│  ┌─────────────────┐     ┌─────────────────┐              │
│  │  Public Subnet  │     │  Private Subnet  │              │
│  │  ┌───────────┐  │     │  ┌───────────┐  │              │
│  │  │  EC2      │  │     │  │  EC2      │  │              │
│  │  │  Instance  │  │     │  │  Instance  │  │              │
│  │  └─────┬─────┘  │     │  └─────┬─────┘  │              │
│  └────────┼─────────┘     └────────┼─────────┘              │
│           │                          │                        │
│  ┌───────┴───────┐      ┌──────────┴─────────┐             │
│  │  Internet     │      │  NAT Gateway/      │             │
│  │  Gateway      │      │  Instance           │             │
│  └───────┬───────┘      └──────────┬─────────┘             │
│           │                          │                        │
└───────────┼──────────────────────────┼────────────────────────┘
            │                          │
    ┌───────┴──────────┐   ┌────────┴──────────┐
    │  Route Table     │   │  Route Table      │
    │  (Public)        │   │  (Private)        │
    └──────────────────┘   └───────────────────┘
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- Basic understanding of networking concepts (IP addressing, subnets, routing)

## Getting Started

### Using CloudFormation

1. **Deploy the VPC stack**
   ```bash
   aws cloudformation create-stack \
     --stack-name my-vpc-stack \
     --template-body file://Cloudformation.yaml \
     --capabilities CAPABILITY_IAM
   ```

2. **Monitor the stack creation**
   ```bash
   aws cloudformation describe-stacks --stack-name my-vpc-stack --query 'Stacks[0].StackStatus'
   ```

### Using AWS CLI

1. **Make the script executable**
   ```bash
   chmod +x create-vpc
   ```

2. **Run the VPC creation script**
   ```bash
   ./create-vpc
   ```

## Project Structure

```
vpc/
├── Cloudformation.yaml    # CloudFormation template for VPC setup
├── create-vpc            # Script to create VPC using AWS CLI
├── README.md             # This file
└── scripts/              # Additional helper scripts
    ├── create-vpc.sh     # VPC creation script
    └── cleanup.sh        # Cleanup script
```

## VPC Components

### 1. VPC

```yaml
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: Production-VPC
```

### 2. Subnets

```yaml
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: Public-Subnet-1
```

### 3. Internet Gateway

```yaml
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: IGW
```

### 4. NAT Gateway

```yaml
  NatGateway:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt EIP.AllocationId
      SubnetId: !Ref PublicSubnet1
      Tags:
        - Key: Name
          Value: NAT-Gateway
```

## Security

### Security Groups

```yaml
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable HTTP and SSH access
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: <YOUR_IP_ADDRESS>/32
```

### Network ACLs

```yaml
  NetworkAcl:
    Type: AWS::EC2::NetworkAcl
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: Custom-NACL
```

## Monitoring

### VPC Flow Logs

```bash
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-12345678 \
  --traffic-type ALL \
  --log-group-name VPCFlowLogs \
  --deliver-logs-permission-arn arn:aws:iam::123456789012:role/FlowLogsRole
```

### CloudWatch Alarms

```yaml
  HighNetworkOutAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmDescription: "Alarm when NetworkOut exceeds 1000000 bytes"
      MetricName: NetworkOut
      Namespace: AWS/EC2
      Statistic: Average
      Period: 300
      EvaluationPeriods: 1
      Threshold: 1000000
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: VPCId
          Value: !Ref VPC
```

## Cost Optimization

### NAT Gateway Optimization

- Use NAT Instances instead of NAT Gateways for development environments
- Consider using VPC endpoints to avoid NAT Gateway costs
- Monitor NAT Gateway metrics and scale down if underutilized

### VPC Flow Logs

- Store flow logs in S3 with lifecycle policies to transition to cheaper storage classes
- Consider sampling flow logs if full logging is not required

## Troubleshooting

### Common Issues

1. **Cannot connect to EC2 instance**
   - Verify security group rules allow the connection
   - Check network ACLs for any explicit denies
   - Ensure the instance has a public IP (for public subnets)
   - Verify the route table has a route to the internet gateway

2. **Private instances cannot access the internet**
   - Verify the NAT Gateway is in a public subnet
   - Check the route table for private subnets has a route to the NAT Gateway
   - Ensure the NAT Gateway has been allocated an Elastic IP

3. **VPC Peering connection issues**
   - Verify the peering connection is in the "active" state
   - Check route tables in both VPCs have routes to each other's CIDR blocks
   - Verify security groups and NACLs allow the necessary traffic

## Cleanup

To avoid ongoing charges, delete the CloudFormation stack when done:

```bash
aws cloudformation delete-stack --stack-name my-vpc-stack
```

Or use the cleanup script:

```bash
./scripts/cleanup.sh my-vpc-stack
```

## Related Resources

- [Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-best-practices.html)
- [VPC Scenarios and Examples](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenarios.html)
- [CloudFormation VPC Templates](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

---

*Note: Always follow the principle of least privilege when configuring security groups and network ACLs. Regularly review and audit your VPC configuration for security best practices.*
./create-vpc
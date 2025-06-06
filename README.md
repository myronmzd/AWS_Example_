# AWS Example Repository

## Overview
This repository contains a collection of AWS service examples and best practices, designed to help developers understand and implement various AWS services effectively. Each directory contains standalone examples with detailed documentation and deployment instructions.

## Table of Contents
- [AWS Services Covered](#aws-services-covered)
- [Getting Started](#getting-started)
- [Service Examples](#service-examples)
- [Best Practices](#best-practices)
- [Contributing](#contributing)
- [License](#license)

## AWS Services Covered

### Compute
- **EC2**: Virtual servers in the cloud
- **Lambda**: Serverless compute service
- **ECS/EKS**: Container orchestration

### Storage
- **S3**: Object storage service
- **EBS**: Block storage for EC2
- **EFS**: Managed file storage

### Networking & Content Delivery
- **VPC**: Virtual private cloud
- **ELB/ALB**: Load balancing
- **Route 53**: DNS and domain management
- **CloudFront**: Content delivery network

### Database
- **RDS**: Managed relational databases
- **DynamoDB**: NoSQL database
- **ElastiCache**: In-memory caching

### Messaging & Integration
- **SNS**: Pub/Sub messaging
- **SQS**: Message queuing service
- **EventBridge**: Event bus service

### Security & Identity
- **IAM**: Identity and access management
- **KMS**: Key management
- **Secrets Manager**: Secrets management

## Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Terraform](https://www.terraform.io/) (for infrastructure as code examples)
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) (for serverless applications)
- Python 3.8+ or Node.js 14+ (for Lambda examples)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/myronmzd/AWS_Example_.git
   cd AWS_Example_
   ```

2. **Navigate to the desired service example**
   ```bash
   cd <service-directory>
   ```

3. **Follow the specific README instructions** for deployment and usage

## Service Examples

### EC2
- **Simple EC2 SSH**: Basic EC2 instance with SSH access
- **Auto Scaling Groups**: Auto-scaling configurations
- **Load Balanced Applications**: EC2 behind Application Load Balancer

### S3
- **Static Website Hosting**: Host a static website
- **Versioning & Lifecycle**: Object versioning and lifecycle policies
- **Cross-Region Replication**: Replicate S3 buckets across regions

### Lambda
- **Basic Lambda Functions**: Simple function examples
- **API Gateway Integration**: REST APIs with Lambda
- **Event Source Mappings**: Process S3, DynamoDB, and Kinesis events

### VPC
- **Basic VPC Setup**: Public and private subnets
- **NAT Gateway**: Outbound internet for private subnets
- **VPC Peering**: Connect multiple VPCs

### SNS & SQS
- **Pub/Sub Messaging**: SNS topics and subscriptions
- **Message Queues**: SQS standard and FIFO queues
- **Fan-Out Pattern**: SNS to multiple SQS queues

## Best Practices

### Security
- Use IAM roles and policies following the principle of least privilege
- Enable encryption at rest and in transit
- Regularly rotate credentials and access keys

### Cost Optimization
- Use AWS Cost Explorer to monitor spending
- Implement auto-scaling for variable workloads
- Clean up unused resources

### Reliability
- Implement multi-AZ deployments for high availability
- Use CloudWatch for monitoring and alerting
- Regular backups and disaster recovery planning

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

*Note: This repository contains example code and configurations. Always review and understand the resources you're creating in your AWS account, as some services may incur costs.*

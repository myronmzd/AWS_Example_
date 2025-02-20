
### Ec2/README.md
```md
# EC2

This folder contains resources and scripts for working with Amazon EC2.

## Contents

- **simple Ec2 SSH/template.yaml**: CloudFormation template to set up VPC, Subnet, NAT Gateway, and an EC2 instance.
- **simple Ec2 SSH/templete.sh**: Bash script to create an EC2 instance with the latest Amazon Linux 2 AMI.

## Features

- **VPC**: Create a Virtual Private Cloud with public and private subnets.
- **EC2 Instance**: Launch an EC2 instance with specified instance type and AMI.
- **Security Groups**: Define security groups to control inbound and outbound traffic.

## Usage

To deploy the EC2 instance using CloudFormation, run the following command:

```sh
aws cloudformation deploy --template-file simple\ Ec2\ SSH/template.yaml --stack-name my-ec2-stack
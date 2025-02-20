# DynamoDB Basics

This folder contains resources and scripts for working with Amazon DynamoDB.

## Contents

- **bin/template.yaml**: CloudFormation template to create a DynamoDB table.

## Features

- **DynamoDB Table**: Create a DynamoDB table with specified attributes and provisioned throughput.

## Usage

To deploy the DynamoDB table using CloudFormation, run the following command:

```sh
aws cloudformation deploy --template-file bin/template.yaml --stack-name my-dynamodb-stack
### vpc/README.md
```md
# VPC

This folder contains resources and scripts for working with Amazon Virtual Private Cloud (VPC).

## Contents

- **create-vpc**: Script to create a VPC.
- **Cloudformation.yaml**: CloudFormation template to set up VPC, Subnet, NAT Gateway, and an EC2 instance.

## Features

- **VPC**: Create a Virtual Private Cloud with public and private subnets.
- **Internet Gateway**: Allow internet access for public subnets.
- **NAT Gateway**: Enable outbound internet traffic for private subnets.
- **Route Tables**: Control traffic routing between subnets and external networks.
- **Security Groups & NACLs**: Define access control rules for inbound and outbound traffic.

## Usage

To create a VPC using the script, run the following command:

```sh
./create-vpc
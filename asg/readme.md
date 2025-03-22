# AWS Auto Scaling Group Deployment

This repository contains a script to deploy an AWS Auto Scaling Group using CloudFormation. The script sets up a VPC, subnets, an Internet Gateway, a Load Balancer, and an Auto Scaling Group with EC2 instances.

## Prerequisites

- AWS CLI installed and configured
- An existing EC2 Key Pair
- IAM permissions to create and manage AWS resources

## Usage

1. Clone the repository:
    ```bash
    git clone https://github.com/your-repo/AWS_Example_.git
    cd AWS_Example_/asg
    ```

2. Make the `deploy.sh` script executable:
    ```bash
    chmod +x deploy.sh
    ```

3. Run the deployment script:
    ```bash
    ./deploy.sh
    ```

## Script Details

The `deploy.sh` script performs the following steps:

1. Retrieves the latest Amazon Linux 2 AMI.
2. Retrieves the public IP address of the user.
3. Creates a CloudFormation template (`template.yaml`) with the following resources:
    - VPC
    - Public Subnets
    - Internet Gateway
    - Route Table and Routes
    - Security Groups
    - Load Balancer and Target Group
    - Launch Template
    - Auto Scaling Group
    - Scaling Policy

4. Checks if the CloudFormation stack exists and updates or creates it accordingly.
5. Monitors the stack creation/update status.

## CloudFormation Template

The CloudFormation template (`template.yaml`) includes the following resources:

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
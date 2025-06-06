# AWS Identity and Access Management (IAM)

This repository contains resources, scripts, and best practices for working with AWS Identity and Access Management (IAM). IAM enables you to manage access to AWS services and resources securely.

## Table of Contents

- [Features](#features)
- [Security Best Practices](#security-best-practices)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Creating IAM Users](#creating-iam-users)
  - [Managing IAM Policies](#managing-iam-policies)
  - [IAM Roles](#iam-roles)
  - [Identity Federation](#identity-federation)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Related Resources](#related-resources)

## Features

- **User Management**: Create, update, and manage IAM users
- **Fine-Grained Permissions**: Define permissions using IAM policies
- **Multi-Factor Authentication (MFA)**: Add an extra layer of security
- **Identity Federation**: Integrate with corporate directories
- **Access Analyzer**: Identify resources shared with external entities
- **Credential Report**: Generate reports of all users and their access keys
- **Password Policy**: Enforce strong password requirements

## Security Best Practices

1. **Use IAM Roles Instead of Long-Term Credentials**
   - Prefer IAM roles for AWS services
   - Use temporary credentials whenever possible

2. **Least Privilege**
   - Grant only the permissions required to perform a task
   - Regularly review and refine permissions

3. **Enable MFA**
   - Require MFA for privileged users
   - Consider MFA for all interactive users

4. **Rotate Credentials**
   - Regularly rotate access keys
   - Remove unused credentials

## Getting Started

### Prerequisites

- AWS Account with administrative access
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- Appropriate IAM permissions to create and manage IAM resources

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-repo/AWS_Example_.git
   cd AWS_Example_/IAM
   ```

2. Make the scripts executable:
   ```bash
   chmod +x CreateUserandpolicy
   ```

## Usage

### Creating IAM Users

#### Using the AWS CLI

```bash
# Create a new IAM user
aws iam create-user --user-name new-user

# Create access keys
aws iam create-access-key --user-name new-user

# Set user password (console access)
aws iam create-login-profile \
  --user-name new-user \
  --password 'YourP@ssword!' \
  --password-reset-required
```

#### Using the Provided Script

```bash
./CreateUserandpolicy
```

### Managing IAM Policies

#### Create a Policy

```bash
# Create a policy from a JSON file
aws iam create-policy \
  --policy-name MyS3ReadOnlyPolicy \
  --policy-document file://s3-readonly-policy.json
```

#### Attach a Policy to a User

```bash
aws iam attach-user-policy \
  --user-name new-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### IAM Roles

#### Create a Role

```bash
# Create a role trust policy document
cat > trust-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

# Create the role
aws iam create-role \
  --role-name MyEC2Role \
  --assume-role-policy-document file://trust-policy.json
```

### Identity Federation

#### Configure SAML 2.0 Federation

```bash
# Create an IAM identity provider
aws iam create-saml-provider \
  --saml-metadata-document file://saml-metadata.xml \
  --name MySAMLProvider
```

## Examples

### Example: Create User with Specific Permissions

```bash
# Create user
aws iam create-user --user-name app-user

# Create and attach inline policy
cat > inline-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
EOL

aws iam put-user-policy \
  --user-name app-user \
  --policy-name S3ReadAccess \
  --policy-document file://inline-policy.json
```

## Best Practices

### General
- Use groups to assign permissions to IAM users
- Configure a strong password policy
- Enable and regularly review CloudTrail logs
- Use IAM Access Analyzer to validate IAM policies

### For Production
- Implement cross-account access roles
- Set up AWS Organizations SCPs
- Use permission boundaries
- Regularly rotate all credentials

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Verify the IAM user/role has the necessary permissions
   - Check for explicit denies in resource-based policies
   - Verify the request is being made in the correct AWS region

2. **InvalidClientTokenId**
   - Verify the access key ID and secret access key are correct
   - Check if the credentials have been deactivated

3. **ExpiredToken**
   - Refresh temporary credentials
   - Check the expiration time of the current credentials

## Security

- **Encryption**: Always use HTTPS for API calls
- **Auditing**: Enable AWS CloudTrail for all API activity
- **Least Privilege**: Regularly audit and refine permissions
- **Incident Response**: Have a plan for compromised credentials

## Related Resources

- [AWS IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS CLI IAM Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/index.html)
- [IAM Policy Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html)
- [AWS Security Blog](https://aws.amazon.com/blogs/security/)

---

*Note: Always follow the principle of least privilege when creating IAM policies and regularly audit your IAM resources for security best practices.*
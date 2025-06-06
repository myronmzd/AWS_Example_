# AWS Security Token Service (STS) Examples

This directory contains examples and resources for working with AWS Security Token Service (STS), which enables you to request temporary, limited-privilege credentials for AWS Identity and Access Management (IAM) users or for users you authenticate (federated users).

## Table of Contents
- [Prerequisites](#prerequisites)
- [Examples](#examples)
  - [Creating a User with No Permissions](#creating-a-user-with-no-permissions)
  - [Creating an IAM Role](#creating-an-iam-role)
  - [Assuming a Role](#assuming-a-role)
- [Best Practices](#best-practices)
- [Related AWS Documentation](#related-aws-documentation)

## Prerequisites
- AWS CLI configured with appropriate permissions
- AWS SDK installed (if using programmatic access)
- Basic understanding of IAM roles and policies

## Examples

### Creating a User with No Permissions
This example demonstrates how to create an IAM user with no permissions initially.

```bash
# Create a new IAM user
aws iam create-user --user-name NoPermissionsUser

# Create access keys for the user
aws iam create-access-key --user-name NoPermissionsUser
```

### Creating an IAM Role
Create a role that can be assumed by the user to access specific resources.

```bash
# Create a trust policy document
cat > trust-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:user/NoPermissionsUser"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

# Create the IAM role
aws iam create-role \
  --role-name ExampleRole \
  --assume-role-policy-document file://trust-policy.json

# Attach policies to the role (example: S3 read-only access)
aws iam attach-role-policy \
  --role-name ExampleRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### Assuming a Role
Use the new user's credentials to assume the role and get temporary security credentials.

```bash
# Configure the AWS CLI with the user's credentials
aws configure set aws_access_key_id ACCESS_KEY
aws configure set aws_secret_access_key SECRET_KEY

# Assume the role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/ExampleRole \
  --role-session-name ExampleSession

# The response will include temporary credentials that can be used to make AWS API calls
```

## Best Practices
1. Always follow the principle of least privilege when creating IAM policies.
2. Use temporary credentials whenever possible instead of long-term access keys.
3. Rotate access keys regularly.
4. Use MFA for additional security when assuming roles.
5. Monitor API activity using AWS CloudTrail.

## Related AWS Documentation
- [AWS STS Documentation](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS CLI STS Commands](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sts/index.html)

import boto3
import botocore
import os

# Expanded AWS services and their respective API calls to check active resources
SERVICES_TO_CHECK = {
    "ec2": "describe_instances",
    "ec2-volumes": "describe_volumes",
    "ec2-snapshots": "describe_snapshots",
    "s3": "list_buckets",
    "rds": "describe_db_instances",
    "lambda": "list_functions",
    "dynamodb": "list_tables",
    "cloudformation": "describe_stacks",
    "iam": "list_users",
    "sqs": "list_queues",
    "sns": "list_topics",
    "ecs": "list_clusters",
    "eks": "list_clusters",
    "elasticache": "describe_cache_clusters",
    "redshift": "describe_clusters",
    "efs": "describe_file_systems",
    "cloudwatch": "describe_alarms",
    "kms": "list_keys",
    "apigateway": "get_rest_apis",
    "logs": "describe_log_groups",
    "secretsmanager": "list_secrets",
    "ssm": "describe_instance_information",
    "route53": "list_hosted_zones",
}

def aws_configured():
    """Check if AWS credentials are configured."""
    session = boto3.Session()
    credentials = session.get_credentials()
    return credentials is not None and credentials.access_key is not None

def check_service_activity(service, operation):
    """Check if an AWS service has active resources."""
    try:
        client = boto3.client(service.split('-')[0])
        method = getattr(client, operation)
        response = method()
        # If the response has a list of items and is not empty, the service is active
        for key, value in response.items():
            if isinstance(value, list) and len(value) > 0:
                return True
    except botocore.exceptions.NoCredentialsError:
        print("❌ AWS credentials not found. Please configure your AWS CLI or environment variables.")
        return None
    except Exception as e:
        # Ignore errors from services that are not enabled or not subscribed
        if "AccessDenied" in str(e) or "not subscribed" in str(e):
            return False
    return False

def list_active_services():
    """Check each AWS service and return a list of active ones."""
    active_services = []
    for service, operation in SERVICES_TO_CHECK.items():
        status = check_service_activity(service, operation)
        if status is None:
            return None  # No credentials, abort further checks
        if status:
            active_services.append(service)
    return sorted(active_services)

def main():
    print("🔎 Checking AWS configuration and active resources...\n")

    if not aws_configured():
        print("⚠️  AWS credentials are NOT configured. Please run 'aws configure' or set environment variables.")
        print("    The script will still attempt to check for resources, but may fail.\n")

    services = list_active_services()

    if services is None:
        print("\n❌ Could not check services due to missing AWS credentials.")
    elif services:
        print("\n✅ AWS Services with Active Resources:")
        for service in services:
            print(f"  - {service}")
    else:
        print("\n❌ No active AWS services found in this account/region.")

if __name__ == "__main__":
    main()

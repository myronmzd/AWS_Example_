import boto3

# AWS services and their respective API calls to check active resources
SERVICES_TO_CHECK = {
    "ec2": "describe_instances",
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
}

def check_service_activity(service, operation):
    """Check if an AWS service has active resources."""
    try:
        client = boto3.client(service)
        method = getattr(client, operation)
        response = method()
        
        # If the response has a list of items and is not empty, the service is active
        for key, value in response.items():
            if isinstance(value, list) and len(value) > 0:
                return True

    except Exception as e:
        # Ignore errors from services that are not enabled
        if "AccessDenied" in str(e) or "not subscribed" in str(e):
            return False

    return False

def list_active_services():
    """Check each AWS service and return a list of active ones."""
    active_services = []

    for service, operation in SERVICES_TO_CHECK.items():
        if check_service_activity(service, operation):
            active_services.append(service)

    return sorted(active_services)

def main():
    print("Fetching all AWS services with active resources...")

    services = list_active_services()

    if services:
        print("\n✅ AWS Services with Active Resources:")
        for service in services:
            print(f"  - {service}")
    else:
        print("\n❌ No active services found.")

if __name__ == "__main__":
    main()

import boto3

def list_active_services():
    """List all AWS services with active resources in the account, excluding default VPCs and subnets."""
    client = boto3.client("resourcegroupstaggingapi")
    
    response = client.get_resources()
    
    active_services = set()
    ignored_resources = ["vpc/", "subnet/"]  # Ignore default VPCs and subnets
    
    for resource in response.get("ResourceTagMappingList", []):
        arn = resource["ResourceARN"]
        
        # Extract service name from ARN
        service = arn.split(":")[2]
        
        # Skip default VPCs and subnets
        if any(ignore in arn for ignore in ignored_resources) and "default" in arn.lower():
            continue
        
        active_services.add(service)
    
    return sorted(active_services)

def main():
    print("Fetching all AWS services with active resources (excluding default VPCs & subnets)...")
    
    services = list_active_services()
    
    if services:
        print("\n✅ AWS Services with Active Resources:")
        for service in services:
            print(f"  - {service}")
    else:
        print("\n❌ No active services found.")

if __name__ == "__main__":
    main()

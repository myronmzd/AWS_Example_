# Serverless ElastiCache Setup and Benchmarking

This guide outlines the steps to create serverless Amazon ElastiCache instances (Valkey and Redis) and benchmark their performance.

## Prerequisites

Before you begin, ensure you have:
* AWS CLI configured with appropriate permissions.
* Existing AWS Security Group IDs (e.g., `sg-06d0c094aa641a478`).
* At least two existing AWS Subnet IDs (e.g., `subnet-016504b33fee4c0bc`, `subnet-03819e478ff2357f5`).

## Create Serverless ElastiCache Instances

You can create serverless ElastiCache instances using the AWS CLI.

### Valkey

To create a serverless Valkey cache:

```bash
aws elasticache create-serverless-cache \
--serverless-cache-name My-ElastiCache-Valkey \
--engine valkey \
--major-engine-version 8 \
--security-group-ids sg-06d0c094aa641a478 \
--subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5
```

Redis
To create a serverless Redis cache:

```bash

aws elasticache create-serverless-cache \
--serverless-cache-name My-ElastiCache-Redis \
--engine Redis \
--major-engine-version 7 \
--security-group-ids sg-06d0c094aa641a478 \
--subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5
```

Note:

Replace My-ElastiCache-Valkey and My-ElastiCache-Redis with your desired cache names.
Ensure you provide at least two subnet IDs.
The security group should allow inbound connections from the EC2 instance you will use for benchmarking.
Connect to EC2 Instance and Copy Benchmarking Script
To benchmark your ElastiCache instances, you'll need to connect to an EC2 instance and transfer your benchmarking script (e.g., benchmarking.py) to it.

# Default SSH Usernames for Common AMIs

AMI Type	Default SSH       Username
Amazon Linux / AL2	        ec2-user
Ubuntu	                    ubuntu
Red Hat Enterprise Linux	  ec2-user
Debian	                    admin

# Export to Sheets
# Copying the Benchmarking Script
# Use the scp command to securely copy your local script to the EC2 instance:

```Bash

scp -i /path/to/your-key.pem /path/to/local-file <EC2-SSH-Username>@<EC2-Public-IP>:/home/<EC2-SSH-Username>/
```
Example:

```Bash

scp -i "C:\Users\Myron\Downloads\mykey.pem" "C:\Users\Myron\Downloads\benchmarking.py" ubuntu@65.2.39.221:/home/ubuntu/
Replace /path/to/your-key.pem, /path/to/local-file, <EC2-SSH-Username>, and <EC2-Public-IP> with your actual values.
```

# Benchmark ElastiCache Instances
After copying the benchmarking.py script to your EC2 instance, you can run it to test the performance of your Valkey and Redis ElastiCache instances.

# Valkey Benchmark Results
📊 Benchmark Results:
SET Operation
  Total Time       : 6.9171 sec
  Throughput       : 1445.70 ops/sec
  Average Latency  : 0.691 ms
  p50 Latency      : 0.674 ms
  p90 Latency      : 0.735 ms
  p99 Latency      : 1.199 ms

GET Operation
  Total Time       : 7.3413 sec
  Throughput       : 1362.15 ops/sec
  Average Latency  : 0.733 ms
  p50 Latency      : 0.668 ms
  p90 Latency      : 0.795 ms
  p99 Latency      : 2.021 ms

DEL Operation
  Total Time       : 6.8729 sec
  Throughput       : 1454.99 ops/sec
  Average Latency  : 0.686 ms
  p50 Latency      : 0.669 ms
  p90 Latency      : 0.730 ms
  p99 Latency      : 1.282 ms
# Redis Benchmark Results

📊 Benchmark Results:
SET Operation
  Total Time       : 6.8298 sec
  Throughput       : 1464.16 ops/sec
  Average Latency  : 0.682 ms
  p50 Latency      : 0.668 ms
  p90 Latency      : 0.730 ms
  p99 Latency      : 0.911 ms

GET Operation
  Total Time       : 6.6429 sec
  Throughput       : 1505.37 ops/sec
  Average Latency  : 0.663 ms
  p50 Latency      : 0.646 ms
  p90 Latency      : 0.714 ms
  p99 Latency      : 0.925 ms

DEL Operation
  Total Time       : 6.6955 sec
  Throughput       : 1493.55 ops/sec
  Average Latency  : 0.669 ms
  p50 Latency      : 0.654 ms
  p90 Latency      : 0.721 ms
  p99 Latency      : 0.881 ms

These results provide a comparison of the SET, GET, and DEL operation performance for both Valkey and Redis serverless caches. You can analyze these metrics to determine which engine better suits your application's needs.


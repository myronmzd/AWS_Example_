# Amazon ElastiCache: Serverless Implementation Guide

This repository provides comprehensive guidance on setting up, configuring, and benchmarking serverless Amazon ElastiCache instances with both Valkey and Redis engines. Amazon ElastiCache is a fully managed, in-memory data store service that delivers high performance and low-latency data access.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Valkey Setup](#valkey-setup)
  - [Redis Setup](#redis-setup)
- [Configuration](#configuration)
- [Security](#security)
- [Performance Benchmarking](#performance-benchmarking)
- [Monitoring](#monitoring)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [Cleanup](#cleanup)
- [Related Resources](#related-resources)

## Features

- **Fully Managed**: No infrastructure to provision or manage
- **Serverless**: Automatically scales based on demand
- **Multi-Engine Support**: Choose between Valkey and Redis engines
- **High Availability**: Built-in replication and failover
- **Security**: Encryption in transit and at rest
- **Monitoring**: Integration with Amazon CloudWatch
- **Backup & Restore**: Point-in-time recovery capabilities

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                           │
│  ┌─────────────┐     ┌─────────────────┐                  │
│  │  Client     │     │  Application    │                  │
│  │  EC2        │     │  Load Balancer  │                  │
│  └──────┬──────┘     └────────┬────────┘                  │
│         │                      │                            │
│         │                      │                            │
│  ┌──────▼──────┐     ┌────────▼────────┐                  │
│  │  Private    │     │  Private        │                  │
│  │  Subnet A   │     │  Subnet B       │                  │
│  └──────┬──────┘     └────────┬────────┘                  │
│         │                      │                            │
│  ┌──────▼──────────────────────▼────────┐     ┌─────────────┐│
│  │  ElastiCache Security Group         │     │  CloudWatch  ││
│  │  ┌───────────────────────────────┐   │     │  Monitoring  ││
│  │  │  Serverless ElastiCache       │   │     │  & Alarms    ││
│  │  │  - Valkey Cluster             │   │     │             ││
│  │  │  - Redis Cluster              │   │     │             ││
│  │  └───────────────────────────────┘   │     │             ││
│  └───────────────────────────────────────┘     └─────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before you begin, ensure you have the following:

### AWS Account Requirements
- Active AWS account with appropriate IAM permissions
- AWS CLI [installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

### Network Configuration
- VPC with at least two private subnets in different Availability Zones
- Security group with appropriate inbound rules:
  - Allow inbound TCP traffic on the cache port (default: 6379) from your application servers
  - For SSH access to benchmarking instances (port 22)
- Subnet group for ElastiCache

### IAM Permissions
Ensure your IAM user/role has permissions for:
- `elasticache:CreateServerlessCache`
- `elasticache:DescribeServerlessCaches`
- `ec2:DescribeSubnets`
- `ec2:DescribeSecurityGroups`

## Getting Started

### Valkey Setup

Create a serverless Valkey cache:

```bash
aws elasticache create-serverless-cache \
  --serverless-cache-name my-valkey-cache \
  --engine valkey \
  --major-engine-version 8 \
  --security-group-ids sg-06d0c094aa641a478 \
  --subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5 \
  --description "Production Valkey cache for application data"
```

### Redis Setup

Create a serverless Redis cache:

```bash
aws elasticache create-serverless-cache \
  --serverless-cache-name my-redis-cache \
  --engine redis \
  --major-engine-version 7 \
  --security-group-ids sg-06d0c094aa641a478 \
  --subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5 \
  --description "Production Redis cache for session management"
```

## Configuration

### Cache Parameters

You can customize your cache with the following parameters:

```bash
# Example: Create cache with custom parameters
aws elasticache create-serverless-cache \
  --serverless-cache-name my-custom-cache \
  --engine redis \
  --major-engine-version 7 \
  --security-group-ids sg-06d0c094aa641a478 \
  --subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5 \
  --cache-usage-limits '{"DataStorage":{"Maximum":1000,"Unit":"GB"},"ECPUPerSecond":{"Maximum":100000}}' \
  --kms-key-id alias/my-key-alias
```

### Tagging

Add tags for better resource management:

```bash
aws elasticache add-tags-to-resource \
  --resource-name arn:aws:elasticache:region:account-id:serverlesscache/my-cache \
  --tags Key=Environment,Value=Production Key=Project,Value=MyApp
```

## Security

### Encryption

- **Encryption in Transit**: Enabled by default for all new caches
- **Encryption at Rest**: Enable using AWS KMS
- **Authentication**: Redis AUTH for an extra layer of security

### Network Security

- Use security groups to control access to your caches
- Place caches in private subnets
- Use VPC endpoints for private connectivity

### IAM Policies

Example IAM policy for least privilege access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticache:Connect",
        "elasticache:Get*",
        "elasticache:List*"
      ],
      "Resource": "arn:aws:elasticache:region:account-id:serverlesscache/my-cache"
    }
  ]
}
```

## Performance Benchmarking

### Benchmarking Setup

1. Launch an EC2 instance in the same VPC as your cache
2. Install benchmarking tools:

```bash
# Install Redis CLI and benchmark tools
sudo yum install -y gcc make
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
```

### Running Benchmarks

Basic benchmark with `redis-benchmark`:

```bash
# Test SET operations
./src/redis-benchmark -h your-cache-endpoint.abc123.0001.use1.cache.amazonaws.com -p 6379 -n 100000 -c 50 -t set

# Test GET operations
./src/redis-benchmark -h your-cache-endpoint.abc123.0001.use1.cache.amazonaws.com -p 6379 -n 100000 -c 50 -t get
```

### Benchmarking Script

For more comprehensive testing, use the provided Python benchmarking script:

```bash
python3 benchmark.py --host your-cache-endpoint --port 6379 --ops 100000 --clients 50
```

## Monitoring

### CloudWatch Metrics

Key metrics to monitor:
- `EngineCPUUtilization`
- `DatabaseMemoryUsagePercentage`
- `CurrConnections`
- `NewConnections`
- `CacheHits` and `CacheMisses`
- `Evictions`

### Setting Up Alarms

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name HighCPUUtilization \
  --alarm-description "Alarm when CPU exceeds 80%" \
  --metric-name EngineCPUUtilization \
  --namespace AWS/ElastiCache \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=CacheClusterId,Value=my-cache \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:region:account-id:my-sns-topic
```

## Best Practices

### Performance

- **Connection Pooling**: Reuse connections to minimize latency
- **Pipelining**: Batch multiple commands to reduce round-trips
- **Data Partitioning**: Distribute data across multiple shards if needed
- **Appropriate Data Types**: Use the most efficient data types for your use case

### Reliability

- **Multi-AZ**: Ensure your cache spans multiple Availability Zones
- **Backup**: Regularly back up your cache data
- **Failover Testing**: Regularly test failover scenarios

### Security

- **Encryption**: Always enable encryption in transit and at rest
- **Authentication**: Use Redis AUTH
- **Network Isolation**: Keep caches in private subnets
- **Least Privilege**: Follow the principle of least privilege for IAM policies

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Verify security group rules
   - Check VPC routing tables
   - Confirm the cache is in the "available" state

2. **Performance Problems**
   - Check for hot keys with `redis-cli --hotkeys`
   - Monitor memory usage and eviction policies
   - Review CloudWatch metrics for bottlenecks

3. **Authentication Failures**
   - Verify the AUTH token is correct
   - Check IAM permissions
   - Confirm the security group allows your IP

## Cost Optimization

- **Right-Sizing**: Choose appropriate cache size and scaling limits
- **Data TTL**: Implement time-to-live for cache entries
- **Monitoring**: Set up cost allocation tags and budgets
- **Reserved Nodes**: Consider reserved nodes for predictable workloads

## Cleanup

To avoid unnecessary charges, delete resources when not in use:

```bash
# Delete a serverless cache
aws elasticache delete-serverless-cache \
  --serverless-cache-name my-cache \
  --final-snapshot-identifier my-final-snapshot

# Delete the subnet group (if no longer needed)
aws elasticache delete-cache-subnet-group \
  --cache-subnet-group-name my-subnet-group
```

## Related Resources

- [Amazon ElastiCache Documentation](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)
- [Serverless ElastiCache User Guide](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Serverless.html)
- [Redis Commands](https://redis.io/commands/)
- [Valkey Documentation](https://valkey.io/documentation)
- [AWS CLI ElastiCache Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elasticache/index.html)
- [ElastiCache Pricing](https://aws.amazon.com/elasticache/pricing/)

---

*Note: Replace placeholder values (e.g., security group IDs, subnet IDs, ARNs) with your actual AWS resource identifiers before running the commands.*

# Export to Sheets
# Copying the Benchmarking Script
# Use the scp command to securely copy your local script to the EC2 instance:

```bash

scp -i /path/to/your-key.pem /path/to/local-file <EC2-SSH-Username>@<EC2-Public-IP>:/home/<EC2-SSH-Username>/
```
Example:

```Bash

scp -i "C:\Users\Myron\Downloads\mykey.pem" "C:\Users\Myron\Downloads\benchmarking.py" ubuntu@65.2.39.221:/home/ubuntu/
Replace /path/to/your-key.pem, /path/to/local-file, <EC2-SSH-Username>, and <EC2-Public-IP> with your actual values.
```

# Benchmark ElastiCache Instances
After copying the benchmarking.py script to your EC2 instance, you can run it to test the performance of your Valkey and Redis ElastiCache instances.

# 🔥 Redis vs Valkey Benchmark Comparison

This document compares the performance of **Redis** and **Valkey** based on SET, GET, and DEL operations using standard benchmarking metrics.

---

## 📝 SET Operation

| **Metric**       | **Redis**     | **Valkey**    | **Winner** |
|------------------|---------------|---------------|------------|
| Total Time       | 6.8298 s      | 6.9171 s      | Redis      |
| Throughput       | 1464.16 ops/sec | 1445.70 ops/sec | Redis   |
| Avg Latency      | 0.682 ms      | 0.691 ms      | Redis      |
| p50 Latency      | 0.668 ms      | 0.674 ms      | Redis      |
| p90 Latency      | 0.730 ms      | 0.735 ms      | Redis      |
| p99 Latency      | 0.911 ms      | 1.199 ms      | Redis      |

---

## 📥 GET Operation

| **Metric**       | **Redis**     | **Valkey**    | **Winner** |
|------------------|---------------|---------------|------------|
| Total Time       | 6.6429 s      | 7.3413 s      | Redis      |
| Throughput       | 1505.37 ops/sec | 1362.15 ops/sec | Redis   |
| Avg Latency      | 0.663 ms      | 0.733 ms      | Redis      |
| p50 Latency      | 0.646 ms      | 0.668 ms      | Redis      |
| p90 Latency      | 0.714 ms      | 0.795 ms      | Redis      |
| p99 Latency      | 0.925 ms      | 2.021 ms      | Redis      |

---

## 🗑️ DEL Operation

| **Metric**       | **Redis**     | **Valkey**    | **Winner** |
|------------------|---------------|---------------|------------|
| Total Time       | 6.6955 s      | 6.8729 s      | Redis      |
| Throughput       | 1493.55 ops/sec | 1454.99 ops/sec | Redis   |
| Avg Latency      | 0.669 ms      | 0.686 ms      | Redis      |
| p50 Latency      | 0.654 ms      | 0.669 ms      | Redis      |
| p90 Latency      | 0.721 ms      | 0.730 ms      | Redis      |
| p99 Latency      | 0.881 ms      | 1.282 ms      | Redis      |

---

## 🏁 Conclusion

Across all operations — SET, GET, and DEL — **Redis** consistently outperforms **Valkey** in throughput, latency, and overall execution time. Redis remains the faster and more responsive choice based on this benchmark.

✅ Winner: Redis
🔍 Why? It consistently provides better performance, especially with lower high-percentile latencies (p90/p99), which matter in real-world apps for user experience under load.

These results provide a comparison of the SET, GET, and DEL operation performance for both Valkey and Redis serverless caches. You can analyze these metrics to determine which engine better suits your application's needs.


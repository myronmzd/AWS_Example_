# AWS T-family Instances (Sorted by Cost)

This list ranks AWS T-family instances from **least expensive** to **most expensive** based on general pricing trends. Prices may vary by region.

## T-family Instances (Low to High Cost)

| Instance Type  | vCPUs | Memory (GiB) | Notes |
|---------------|------|-------------|-------------------------------|
| **t4g.nano**  | 2    | 0.5         | Cheapest, ARM-based (Graviton) |
| **t3.nano**   | 2    | 0.5         | Cheapest in x86-based T3 family |
| **t4g.micro** | 2    | 1           | More memory, still ARM-based |
| **t3a.nano**  | 2    | 0.5         | AMD-based, slightly cheaper than t3 |
| **t2.nano**   | 1    | 0.5         | Older generation |
| **t3a.micro** | 2    | 1           | AMD-based alternative to t3.small |
| **t4g.small** | 2    | 2           | Smallest Graviton-based with 2 GiB RAM |
| **t3.small**  | 2    | 2           | Smallest in T3 family |
| **t3a.small** | 2    | 2           | AMD-based, slightly cheaper |
| **t2.micro**  | 1    | 1           | Free-tier eligible but older |
| **t2.small**  | 1    | 2           | Slightly better than t2.micro |
| **t3.medium** | 2    | 4           | Mid-tier T3 instance |
| **t3a.medium**| 2    | 4           | AMD-based, slightly cheaper |
| **t2.medium** | 2    | 4           | Older but still available |
| **t3.large**  | 2    | 8           | More memory-intensive workloads |
| **t3a.large** | 2    | 8           | AMD-based, lower cost than t3.large |
| **t2.large**  | 2    | 8           | Older generation |
| **t3.xlarge** | 4    | 16          | More compute power |
| **t3a.xlarge**| 4    | 16          | AMD-based |
| **t2.xlarge** | 4    | 16          | Older but still available |
| **t3.2xlarge**| 8    | 32          | Most expensive in T3 |
| **t3a.2xlarge**| 8   | 32          | AMD-based |
| **t2.2xlarge**| 8    | 32          | Older but high memory |

## Pricing Notes
- **T4g instances** (Graviton, ARM-based) are usually **cheapest** in each category.
- **T3a instances** (AMD-based) are slightly **cheaper** than T3.
- **T2 instances** are older but still available in many regions.
- **T3 and T3a** are more **cost-efficient** than T2 due to better performance per dollar.

### Need pricing for a specific AWS region?
Run this command in the AWS CLI:
```bash
# Sort by Memory (Ascending)
aws ec2 describe-instance-types --query "sort_by(InstanceTypes[?starts_with(InstanceType, 't')], &MemoryInfo.SizeInMiB)[].[InstanceType, MemoryInfo.SizeInMiB, VCpuInfo.DefaultVCpus]" --output table


# Sort by vCPUs (Ascending)
aws ec2 describe-instance-types --query "sort_by(InstanceTypes[?starts_with(InstanceType, 't')], &VCpuInfo.DefaultVCpus)[].[InstanceType, MemoryInfo.SizeInMiB, VCpuInfo.DefaultVCpus]" --output table

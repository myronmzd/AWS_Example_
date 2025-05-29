# create serverless ElastiCashe

# valkey 

```bash
aws elasticache create-serverless-cache \
--serverless-cache-name My-ElastiCache \
--engine valkey \
--major-engine-version 8 \
--security-group-ids 	sg-06d0c094aa641a478 \
--subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5  # alteasty two need 

``` 
# Redis 


```bash
aws elasticache create-serverless-cache \
--serverless-cache-name My-ElastiCache \
--engine Redis \
--major-engine-version 7 \
--security-group-ids 	sg-06d0c094aa641a478 \
--subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5  # alteasty two need 

``` 
# connect to ec2 intance 
# copy benchmarking.py on ec2 intance 

AMI Type	            Default SSH Username
Amazon Linux / AL2	        ec2-user
Ubuntu	                    ubuntu
Red Hat Enterprise Linux	ec2-user
Debian	                    admin

scp -i /path/to/your-key.pem /path/to/local-file ec2-user@<EC2-Public-IP>:/home/ec2-user/

scp -i "C:\Users\Myron\Downloads\mykey.pem" "C:\Users\Myron\Downloads\benchmarking.py" ubuntu@65.2.39.221:/home/ubuntu/

# test which elasticash is better 


valkey 

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


redis 


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



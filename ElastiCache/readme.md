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

scp -i mykey.pem benchmarking.py ec2-user@ec2-3-12-34-56.compute-1.amazonaws.com:/home/ec2-user/


# test which elasticash is better 





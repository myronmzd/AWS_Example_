aws elasticache create-serverless-cache \
--serverless-cache-name My-ElastiCache-valkey \
--engine valkey \
--major-engine-version 8 \
--security-group-ids sg-06d0c094aa641a478 \
--subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5 

# alteasty two subnets needed in launching the serverless cache

aws elasticache create-serverless-cache \
--serverless-cache-name My-ElastiCache-redis \
--engine redis \
--major-engine-version 7 \
--security-group-ids sg-06d0c094aa641a478 \
--subnet-ids subnet-016504b33fee4c0bc subnet-03819e478ff2357f5  

# alteasty two subnets needed in launching the serverless cache
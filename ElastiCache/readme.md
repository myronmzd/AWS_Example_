# create serverless ElastiCashe

aws elasticache create-serverless-cache \
  --serverless-cache-name My-ElastiCache \
  --engine valkey \
  --major-engine-version 8 \
  --security-group-ids sg-0f3e49cff650c2e0e \
  --subnet-ids subnet-0e6dc7b510da19976 subnet-0ab4a912390c39bc7  # alteasty two need 

  # 



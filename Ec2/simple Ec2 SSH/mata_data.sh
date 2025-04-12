#!/bin/bash

echo "Requesting token for IMDSv2..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [ -z "$TOKEN" ]; then
  echo "Failed to get IMDSv2 token. Exiting."
  exit 1
fi

echo "Token acquired. Fetching metadata..."
META_URL="http://169.254.169.254/latest/meta-data"

# Get the top-level metadata keys
KEYS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$META_URL/")

echo ""
echo "==== EC2 Instance Metadata ===="
echo ""

# Loop through each key and get its value
for key in $KEYS; do
  VALUE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$META_URL/$key")

  # If value ends with "/", it's a directory, skip or go deeper if needed
  if [[ "$key" == */ ]]; then
    echo "$key => [directory]"
  else
    echo "$key => $VALUE"
  fi
done

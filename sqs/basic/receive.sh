#!/usr/bin/env bash

echo  "== receive message "

# Check if a Queue name is provided
if [ -z "$1" ]; then 
    echo "❌ There needs to be a queue name"
    exit 1
fi 

QUEUE=$1

aws sqs receive-message \
    --queue-url "$QUEUE" \
    --attribute-names All \
    --region ap-south-1 \
    --message-attribute-names All \
    --max-number-of-messages 10
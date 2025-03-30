#!/usr/bin/env bash

echo  "== send message "

# Check if a Queue name is provided
if [ -z "$1" ]; then 
    echo "❌ There needs to be a queue name"
    exit 1
fi 

QUEUE=$1

aws sqs send-message \
--queue-url "$QUEUE" \
--message-body "Information about the largest city in Any Region." \
--delay-seconds 10 --message-attributes file://message.json
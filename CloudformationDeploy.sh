#!/bin/bash

# Check if input argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <folder-path or template-file>"
    exit 1
fi

INPUT_PATH="$1"

# If the input is a file, use it directly
if [ -f "$INPUT_PATH" ]; then
    TEMPLATE_FILE="$INPUT_PATH"
else
    # If it's a folder, find the first CloudFormation template (YAML or JSON)
    if [ ! -d "$INPUT_PATH" ]; then
        echo "Error: Provided path is neither a valid file nor a folder."
        exit 1
    fi

    TEMPLATE_FILE=$(find "$INPUT_PATH" -maxdepth 1 \( -name "*.yaml" -o -name "*.json" \) | head -n 1)

    if [ -z "$TEMPLATE_FILE" ]; then
        echo "Error: No CloudFormation template found in the folder."
        exit 1
    fi
fi

echo "Using template: $TEMPLATE_FILE"

# Extract stack name from the filename (without extension)
STACK_NAME=$(basename "$TEMPLATE_FILE" | sed 's/\.[^.]*$//')

echo "Deploying CloudFormation stack: $STACK_NAME"

# Validate the CloudFormation template before deployment
aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" || { echo "Error: Template validation failed."; exit 1; }

# Deploy stack
aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

if [ $? -eq 0 ]; then
    echo "Deployment successful!"
else
    echo "Deployment failed."
    exit 1
fi

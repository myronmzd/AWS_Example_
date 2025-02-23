# Use a lightweight Python base image
FROM mcr.microsoft.com/devcontainers/python:3.11

# Install Node.js and AWS CLI in one step for caching
RUN apt-get update && apt-get install -y nodejs npm awscli && \
    npm install -g aws-cdk && \
    pip install --no-cache-dir boto3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set default shell
SHELL ["/bin/bash", "-c"]

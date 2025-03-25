# Install Node.js, AWS CLI, and AWS SAM CLI
RUN apt-get update && apt-get install -y \
    nodejs npm awscli unzip && \
    npm install -g aws-cdk && \
    pip install --no-cache-dir boto3 aws-sam-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV AWS_CLI_AUTO_PROMPT=on-partial

# Set default shell
SHELL ["/bin/bash", "-c"]

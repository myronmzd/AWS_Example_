# Install dependencies
RUN apt-get update && apt-get install -y \
    nodejs npm awscli unzip python3-pip && \
    npm install -g aws-cdk aws-sam-cli && \
    pip install --no-cache-dir boto3 && \
    apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV AWS_CLI_AUTO_PROMPT=on-partial

# Set default shell
SHELL ["/bin/bash", "-c"]

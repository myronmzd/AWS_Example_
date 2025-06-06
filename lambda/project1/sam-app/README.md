# AWS Lambda Serverless Application

This project demonstrates a serverless application built with AWS Lambda and the Serverless Application Model (SAM). It provides a foundation for building scalable, event-driven applications in the cloud with minimal infrastructure management.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Local Development](#local-development)
  - [Deployment](#deployment)
- [Project Structure](#project-structure)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Security](#security)
- [Scaling](#scaling)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [License](#license)
- [Resources](#resources)

## Features

- **Serverless Architecture**: No servers to manage, automatic scaling
- **Multiple Language Support**: Write functions in Python, Node.js, Java, Go, .NET, or Ruby
- **Event-Driven**: Integrates with 200+ AWS services as event sources
- **Pay-per-Use Billing**: Only pay for the compute time you consume
- **Built-in High Availability**: Automatic multi-AZ deployment
- **Infrastructure as Code**: Define resources using AWS SAM or CloudFormation

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                           │
│  ┌─────────────┐     ┌─────────────────┐                  │
│  │  API        │     │  Event Sources  │                  │
│  │  Gateway    │     │  (S3, SQS,      │                  │
│  └──────┬──────┘     │  DynamoDB, etc) │                  │
│         │             └────────┬────────┘                  │
│         │                      │                            │
│  ┌──────▼──────┐     ┌────────▼────────┐     ┌─────────────┐│
│  │  AWS        │     │  AWS Lambda     │     │  AWS X-Ray  ││
│  │  CloudWatch  │     │  Functions      │     │  Tracing     ││
│  │  Logs       │     │                 │     │             ││
│  └─────────────┘     └─────────────────┘     └─────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before you begin, ensure you have the following installed:

- **AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **AWS SAM CLI**: [Installation Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- **Docker**: [Installation Guide](https://docs.docker.com/get-docker/)
- **Python 3.8+**: [Download Python](https://www.python.org/downloads/)
- **Node.js 14.x+** (if using Node.js runtime): [Download Node.js](https://nodejs.org/)

## Getting Started

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo/lambda/project1/sam-app
   ```

2. **Install dependencies**
   ```bash
   # For Python functions
   pip install -r hello_world/requirements.txt
   
   # For Node.js functions
   cd hello_world && npm install && cd ..
   ```

3. **Build the application**
   ```bash
   sam build --use-container
   ```

4. **Test locally**
   ```bash
   # Invoke function with test event
   sam local invoke HelloWorldFunction --event events/event.json
   
   # Start local API Gateway
   sam local start-api
   # In another terminal, test the API
   curl http://localhost:3000/hello
   ```

### Deployment

1. **Configure AWS credentials**
   ```bash
   aws configure
   ```

2. **Deploy the application**
   ```bash
   sam deploy --guided
   ```
   
   Follow the interactive prompts to configure your deployment.

3. **Verify deployment**
   ```bash
   # Get the API endpoint from the output
   aws cloudformation describe-stacks \
     --stack-name your-stack-name \
     --query 'Stacks[].Outputs[?OutputKey==`HelloWorldApi`].OutputValue' \
     --output text
   ```

## Project Structure

```
sam-app/
├── hello_world/              # Lambda function code
│   ├── app.py                # Main Lambda handler
│   ├── requirements.txt       # Python dependencies
│   └── tests/                # Unit tests
├── events/                   # Test events
│   └── event.json            # Sample test event
├── tests/                    # Integration tests
│   ├── unit/                 # Unit tests
│   └── integration/          # Integration tests
├── template.yaml             # SAM template
└── README.md                # This file
```

## API Reference

### `GET /hello`

Returns a greeting message.

**Response**
```json
{
  "message": "hello world"
}
```

### `POST /hello`

Echoes back the request body with a greeting.

**Request**
```json
{
  "name": "John"
}
```

**Response**
```json
{
  "message": "Hello John!"
}
```

## Testing

### Unit Tests

```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run unit tests
python -m pytest tests/unit -v
```

### Integration Tests

```bash
# Set the stack name as an environment variable
export AWS_SAM_STACK_NAME=your-stack-name

# Run integration tests
python -m pytest tests/integration -v
```

## Monitoring

### CloudWatch Logs

View function logs:
```bash
sam logs -n HelloWorldFunction --stack-name your-stack-name --tail
```

### AWS X-Ray

Enable X-Ray tracing in `template.yaml`:
```yaml
Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      Tracing: Active
```

## Security

### IAM Permissions

Follow the principle of least privilege. The default template includes a basic IAM role with CloudWatch Logs permissions.

### Environment Variables

Store sensitive information using AWS Systems Manager Parameter Store or AWS Secrets Manager:

```yaml
Environment:
  Variables:
    DATABASE_URL: '{{resolve:ssm:/app/database/url:1}}'
    API_KEY: '{{resolve:secretsmanager:MySecret:SecretString:APIKey}}'
```

## Scaling

### Concurrency

Configure reserved concurrency to control the maximum number of concurrent executions:

```yaml
Properties:
  ReservedConcurrentExecutions: 100
```

### Timeout

Adjust the function timeout (up to 15 minutes):

```yaml
Properties:
  Timeout: 30
```

## Cost Optimization

### Memory Allocation

Right-size memory allocation (128MB to 10,240MB in 1MB increments):

```yaml
Properties:
  MemorySize: 256
```

### Provisioned Concurrency

For predictable traffic patterns, use provisioned concurrency to reduce cold starts:

```yaml
AutoPublishAlias: live
ProvisionedConcurrencyConfig:
  ProvisionedConcurrentExecutions: 10
```

## Troubleshooting

### Common Issues

1. **Deployment Failures**
   - Check CloudFormation events: `aws cloudformation describe-stack-events --stack-name your-stack-name`
   - Verify IAM permissions
   - Check resource limits in your AWS account

2. **Function Timeouts**
   - Increase the timeout value
   - Check for long-running operations
   - Verify VPC configuration if accessing private resources

3. **Cold Start Performance**
   - Use provisioned concurrency
   - Optimize package size
   - Use AWS Lambda SnapStart (for Java functions)

## Cleanup

To delete the application and all its resources:

```bash
aws cloudformation delete-stack --stack-name your-stack-name
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)
- [AWS Serverless Application Repository](https://aws.amazon.com/serverless/serverlessrepo/)
- [AWS SAM GitHub Examples](https://github.com/aws-samples/serverless-patterns/)

---

*Note: Replace placeholders (e.g., `your-stack-name`, `your-username/your-repo`) with your actual values before running the commands.*

# Altcha CAPTCHA API Infrastructure

This Terraform configuration deploys the Altcha CAPTCHA Verification API as a serverless solution on AWS.

## Architecture Overview

The infrastructure includes:

- **API Gateway**: RESTful API with two endpoints (`/v1/captcha/challenge` and `/v1/captcha/verify`)
- **Lambda Functions**: Node.js functions for challenge generation and token verification
- **DynamoDB Tables**: Storage for app configurations and token replay protection
- **CloudWatch**: Logging, monitoring, and alerting
- **IAM Roles**: Least-privilege access for Lambda functions
- **SNS**: Alert notifications

## File Structure

```
terraform/
├── 00-variables.tf      # Input variables
├── 01-backend.tf        # Terraform backend configuration
├── 02-provider.tf       # AWS provider configuration
├── iam.tf              # IAM roles and policies
├── lambda.tf           # Lambda functions and DynamoDB tables
├── api-gateway.tf      # API Gateway configuration
├── cloudwatch.tf       # Monitoring and alerting
├── 99-outputs.tf       # Output values
├── lambda_code/        # Lambda function source code
│   ├── create_package.sh   # Build script
│   ├── package.zip         # Deployment package
│   └── src/               # Source code directory
│       ├── package.json
│       ├── challenge.js   # Challenge endpoint handler
│       └── verify.js      # Verify endpoint handler
└── tfvars/             # Environment-specific variables
```

## Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Node.js and npm (for Lambda function dependencies)

### Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Create environment-specific variables**:
   ```bash
   cp tfvars/new.tfvars tfvars/dev.tfvars
   # Edit tfvars/dev.tfvars with your values
   ```

3. **Plan deployment**:
   ```bash
   terraform plan -var-file="tfvars/dev.tfvars"
   ```

4. **Deploy infrastructure**:
   ```bash
   terraform apply -var-file="tfvars/dev.tfvars"
   ```

### Lambda Code Updates

To update Lambda function code:

1. Modify files in `lambda_code/src/`
2. Run the build script:
   ```bash
   cd lambda_code
   ./create_package.sh
   ```
3. Apply Terraform changes:
   ```bash
   terraform apply -var-file="tfvars/dev.tfvars"
   ```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region for deployment | `us-east-2` |
| `environment` | Environment name (dev, staging, prod) | `dev` |
| `project_name` | Name of the project | `altcha-captcha-api` |

### Environment Variables (Lambda)

The Lambda functions receive these environment variables:

- `NODE_ENV`: Environment name
- `REGION`: AWS region
- `APPS_TABLE_NAME`: DynamoDB table for app configurations
- `TOKENS_TABLE_NAME`: DynamoDB table for token replay protection

## API Endpoints

After deployment, the API will be available at:

- **Base URL**: `https://{api-id}.execute-api.{region}.amazonaws.com/{environment}`
- **Challenge**: `POST /v1/captcha/challenge`
- **Verify**: `POST /v1/captcha/verify`

## Monitoring

### CloudWatch Dashboard

A dashboard is created with key metrics for:
- Lambda function invocations, errors, and duration
- API Gateway request counts and error rates

### Alarms

Alarms are configured for:
- Lambda function errors (threshold: 5 errors in 10 minutes)
- Lambda function duration (challenge: 5s, verify: 3s)
- API Gateway 4XX errors (threshold: 50 in 10 minutes)
- API Gateway 5XX errors (threshold: 10 in 10 minutes)

### Logs

- Lambda logs: `/aws/lambda/altcha-challenge` and `/aws/lambda/altcha-verify`
- API Gateway logs: `/aws/apigateway/altcha-captcha-api`
- Log retention: 30 days

## Security

### IAM Permissions

Lambda functions have minimal permissions:
- DynamoDB: Read/write access to app and token tables
- Secrets Manager: Read access to app secrets
- SSM: Read access to system parameters
- CloudWatch: Log creation and X-Ray tracing

### API Security

- HTTPS enforced for all endpoints
- CORS configured for browser compatibility
- Request validation using JSON schemas
- Rate limiting via API Gateway usage plans

## Cost Optimization

- **Lambda**: Pay-per-request with 512MB memory allocation
- **DynamoDB**: On-demand billing mode
- **API Gateway**: Regional endpoints for lower latency
- **CloudWatch**: 30-day log retention to manage storage costs

## Troubleshooting

### Common Issues

1. **Lambda deployment fails**: Check that `create_package.sh` runs successfully
2. **API Gateway 5XX errors**: Check Lambda function logs in CloudWatch
3. **CORS issues**: Verify OPTIONS method responses include correct headers

### Useful Commands

```bash
# View Lambda logs
aws logs tail /aws/lambda/altcha-challenge --follow

# Test API endpoints
curl -X POST https://{api-id}.execute-api.{region}.amazonaws.com/{env}/v1/captcha/challenge \
  -H "Content-Type: application/json" \
  -H "X-App-Id: test-app" \
  -H "X-Api-Key: test-key" \
  -d '{"appId": "test-app"}'

# Check DynamoDB tables
aws dynamodb scan --table-name altcha-apps
```

## Next Steps

1. Implement proper Altcha protocol in Lambda functions
2. Set up app registration and API key management
3. Configure Secrets Manager for app secrets
4. Set up CI/CD pipeline for automated deployments
5. Add integration tests
6. Configure custom domain name for API Gateway
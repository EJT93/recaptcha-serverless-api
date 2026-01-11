# API Gateway Outputs
output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.altcha_api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.altcha_api.id
}

output "api_gateway_stage" {
  description = "Stage name of the API Gateway"
  value       = aws_api_gateway_stage.altcha_stage.stage_name
}

# Lambda Function Outputs
output "challenge_lambda_function_name" {
  description = "Name of the challenge Lambda function"
  value       = aws_lambda_function.challenge.function_name
}

output "verify_lambda_function_name" {
  description = "Name of the verify Lambda function"
  value       = aws_lambda_function.verify.function_name
}

output "challenge_lambda_arn" {
  description = "ARN of the challenge Lambda function"
  value       = aws_lambda_function.challenge.arn
}

output "verify_lambda_arn" {
  description = "ARN of the verify Lambda function"
  value       = aws_lambda_function.verify.arn
}

# DynamoDB Outputs
output "apps_table_name" {
  description = "Name of the apps DynamoDB table"
  value       = aws_dynamodb_table.altcha_apps.name
}

output "tokens_table_name" {
  description = "Name of the tokens DynamoDB table"
  value       = aws_dynamodb_table.altcha_tokens.name
}

output "apps_table_arn" {
  description = "ARN of the apps DynamoDB table"
  value       = aws_dynamodb_table.altcha_apps.arn
}

output "tokens_table_arn" {
  description = "ARN of the tokens DynamoDB table"
  value       = aws_dynamodb_table.altcha_tokens.arn
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.altcha_dashboard.dashboard_name}"
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

# IAM Outputs
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.altcha_lambda_role.arn
}

# Endpoint URLs
output "challenge_endpoint_url" {
  description = "Full URL for the challenge endpoint"
  value       = "https://${aws_api_gateway_rest_api.altcha_api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}/v1/captcha/challenge"
}

output "verify_endpoint_url" {
  description = "Full URL for the verify endpoint"
  value       = "https://${aws_api_gateway_rest_api.altcha_api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}/v1/captcha/verify"
}
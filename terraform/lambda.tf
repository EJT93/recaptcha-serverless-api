# Data source for Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/src"
  output_path = "${path.module}/lambda_code/package.zip"
  depends_on  = [null_resource.lambda_package]
}

# Null resource to build Lambda package
resource "null_resource" "lambda_package" {
  triggers = {
    # Rebuild if any source files change
    src_hash = data.archive_file.lambda_zip.output_base64sha256
  }

  provisioner "local-exec" {
    command     = "./create_package.sh"
    working_dir = "${path.module}/lambda_code"
  }
}

# Challenge Lambda Function
resource "aws_lambda_function" "challenge" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "altcha-challenge"
  role            = aws_iam_role.altcha_lambda_role.arn
  handler         = "challenge.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 512
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NODE_ENV = var.environment
      REGION   = var.region
      APPS_TABLE_NAME = aws_dynamodb_table.altcha_apps.name
      TOKENS_TABLE_NAME = aws_dynamodb_table.altcha_tokens.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.challenge_lambda_logs,
    null_resource.lambda_package
  ]

  tags = {
    Name        = "Altcha Challenge Lambda"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# Verify Lambda Function
resource "aws_lambda_function" "verify" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "altcha-verify"
  role            = aws_iam_role.altcha_lambda_role.arn
  handler         = "verify.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 512
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NODE_ENV = var.environment
      REGION   = var.region
      APPS_TABLE_NAME = aws_dynamodb_table.altcha_apps.name
      TOKENS_TABLE_NAME = aws_dynamodb_table.altcha_tokens.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.verify_lambda_logs,
    null_resource.lambda_package
  ]

  tags = {
    Name        = "Altcha Verify Lambda"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "challenge_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.challenge.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.altcha_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "verify_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.altcha_api.execution_arn}/*/*"
}

# DynamoDB Tables
resource "aws_dynamodb_table" "altcha_apps" {
  name           = "altcha-apps"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"

  attribute {
    name = "appId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  tags = {
    Name        = "Altcha Apps Table"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

resource "aws_dynamodb_table" "altcha_tokens" {
  name           = "altcha-tokens"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "tokenHash"

  attribute {
    name = "tokenHash"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Name        = "Altcha Tokens Table"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}
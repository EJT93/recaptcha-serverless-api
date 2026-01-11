# API Gateway REST API
resource "aws_api_gateway_rest_api" "altcha_api" {
  name        = "altcha-captcha-api"
  description = "Altcha CAPTCHA Verification API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Altcha CAPTCHA API"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# API Gateway Account (for CloudWatch logging)
resource "aws_api_gateway_account" "altcha_api_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

# API Gateway Resources
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  parent_id   = aws_api_gateway_rest_api.altcha_api.root_resource_id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "captcha" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "captcha"
}

resource "aws_api_gateway_resource" "challenge" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  parent_id   = aws_api_gateway_resource.captcha.id
  path_part   = "challenge"
}

resource "aws_api_gateway_resource" "verify" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  parent_id   = aws_api_gateway_resource.captcha.id
  path_part   = "verify"
}

# Challenge Endpoint Methods
resource "aws_api_gateway_method" "challenge_post" {
  rest_api_id   = aws_api_gateway_rest_api.altcha_api.id
  resource_id   = aws_api_gateway_resource.challenge.id
  http_method   = "POST"
  authorization = "NONE"

  request_validator_id = aws_api_gateway_request_validator.altcha_validator.id
  
  request_models = {
    "application/json" = aws_api_gateway_model.challenge_request.name
  }
}

resource "aws_api_gateway_method" "challenge_options" {
  rest_api_id   = aws_api_gateway_rest_api.altcha_api.id
  resource_id   = aws_api_gateway_resource.challenge.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Verify Endpoint Methods
resource "aws_api_gateway_method" "verify_post" {
  rest_api_id   = aws_api_gateway_rest_api.altcha_api.id
  resource_id   = aws_api_gateway_resource.verify.id
  http_method   = "POST"
  authorization = "NONE"

  request_validator_id = aws_api_gateway_request_validator.altcha_validator.id
  
  request_models = {
    "application/json" = aws_api_gateway_model.verify_request.name
  }
}

resource "aws_api_gateway_method" "verify_options" {
  rest_api_id   = aws_api_gateway_rest_api.altcha_api.id
  resource_id   = aws_api_gateway_resource.verify.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
# Lambda Integrations
resource "aws_api_gateway_integration" "challenge_lambda" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.challenge.id
  http_method = aws_api_gateway_method.challenge_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.challenge.invoke_arn
}

resource "aws_api_gateway_integration" "verify_lambda" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.verify.id
  http_method = aws_api_gateway_method.verify_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.verify.invoke_arn
}

# CORS Integrations
resource "aws_api_gateway_integration" "challenge_options" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.challenge.id
  http_method = aws_api_gateway_method.challenge_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration" "verify_options" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.verify.id
  http_method = aws_api_gateway_method.verify_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}
# Method Responses
resource "aws_api_gateway_method_response" "challenge_200" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.challenge.id
  http_method = aws_api_gateway_method.challenge_post.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "verify_200" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.verify.id
  http_method = aws_api_gateway_method.verify_post.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin" = true
  }
}

# CORS Method Responses
resource "aws_api_gateway_method_response" "challenge_options_200" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.challenge.id
  http_method = aws_api_gateway_method.challenge_options.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Headers" = true
    "Access-Control-Allow-Methods" = true
    "Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "verify_options_200" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.verify.id
  http_method = aws_api_gateway_method.verify_options.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Headers" = true
    "Access-Control-Allow-Methods" = true
    "Access-Control-Allow-Origin"  = true
  }
}
# Integration Responses
resource "aws_api_gateway_integration_response" "challenge_options_200" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.challenge.id
  http_method = aws_api_gateway_method.challenge_options.http_method
  status_code = aws_api_gateway_method_response.challenge_options_200.status_code

  response_headers = {
    "Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-App-Id,Origin'"
    "Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "verify_options_200" {
  rest_api_id = aws_api_gateway_rest_api.altcha_api.id
  resource_id = aws_api_gateway_resource.verify.id
  http_method = aws_api_gateway_method.verify_options.http_method
  status_code = aws_api_gateway_method_response.verify_options_200.status_code

  response_headers = {
    "Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-App-Id,Origin,X-Forwarded-For'"
    "Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "Access-Control-Allow-Origin"  = "'*'"
  }
}

# Request Validator
resource "aws_api_gateway_request_validator" "altcha_validator" {
  name                        = "altcha-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.altcha_api.id
  validate_request_body       = true
  validate_request_parameters = true
}
# Request Models
resource "aws_api_gateway_model" "challenge_request" {
  rest_api_id  = aws_api_gateway_rest_api.altcha_api.id
  name         = "ChallengeRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "Challenge Request Schema"
    type      = "object"
    required  = ["appId"]
    properties = {
      appId = {
        type      = "string"
        pattern   = "^[a-zA-Z0-9-]{1,64}$"
        minLength = 1
        maxLength = 64
      }
      clientHints = {
        type = "object"
        properties = {
          difficulty = {
            type    = "number"
            minimum = 1
            maximum = 100000
          }
          expires = {
            type    = "number"
            minimum = 60
            maximum = 3600
          }
        }
        additionalProperties = false
      }
    }
    additionalProperties = false
  })
}

resource "aws_api_gateway_model" "verify_request" {
  rest_api_id  = aws_api_gateway_rest_api.altcha_api.id
  name         = "VerifyRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "Verify Request Schema"
    type      = "object"
    required  = ["appId", "token"]
    properties = {
      appId = {
        type      = "string"
        pattern   = "^[a-zA-Z0-9-]{1,64}$"
        minLength = 1
        maxLength = 64
      }
      token = {
        type      = "string"
        minLength = 1
        maxLength = 2048
      }
      clientInfo = {
        type = "object"
        properties = {
          ip = {
            type = "string"
          }
          userAgent = {
            type = "string"
          }
        }
        additionalProperties = false
      }
    }
    additionalProperties = false
  })
}
# API Gateway Deployment
resource "aws_api_gateway_deployment" "altcha_deployment" {
  depends_on = [
    aws_api_gateway_integration.challenge_lambda,
    aws_api_gateway_integration.verify_lambda,
    aws_api_gateway_integration.challenge_options,
    aws_api_gateway_integration.verify_options,
  ]

  rest_api_id = aws_api_gateway_rest_api.altcha_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.v1.id,
      aws_api_gateway_resource.captcha.id,
      aws_api_gateway_resource.challenge.id,
      aws_api_gateway_resource.verify.id,
      aws_api_gateway_method.challenge_post.id,
      aws_api_gateway_method.verify_post.id,
      aws_api_gateway_integration.challenge_lambda.id,
      aws_api_gateway_integration.verify_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "altcha_stage" {
  deployment_id = aws_api_gateway_deployment.altcha_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.altcha_api.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      responseTime   = "$context.responseTime"
      error          = "$context.error.message"
      integrationError = "$context.integration.error"
    })
  }

  xray_tracing_enabled = true

  tags = {
    Name        = "Altcha API Stage"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "altcha_usage_plan" {
  name         = "altcha-usage-plan"
  description  = "Usage plan for Altcha CAPTCHA API"

  api_stages {
    api_id = aws_api_gateway_rest_api.altcha_api.id
    stage  = aws_api_gateway_stage.altcha_stage.stage_name
  }

  quota_settings {
    limit  = 100000
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = 1000
    burst_limit = 2000
  }

  tags = {
    Name        = "Altcha Usage Plan"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}
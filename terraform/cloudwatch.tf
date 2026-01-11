# CloudWatch Log Groups for Lambda Functions
resource "aws_cloudwatch_log_group" "challenge_lambda_logs" {
  name              = "/aws/lambda/altcha-challenge"
  retention_in_days = 30

  tags = {
    Name        = "Altcha Challenge Lambda Logs"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

resource "aws_cloudwatch_log_group" "verify_lambda_logs" {
  name              = "/aws/lambda/altcha-verify"
  retention_in_days = 30

  tags = {
    Name        = "Altcha Verify Lambda Logs"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/altcha-captcha-api"
  retention_in_days = 30

  tags = {
    Name        = "Altcha API Gateway Logs"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# CloudWatch Alarms for Lambda Functions
resource "aws_cloudwatch_metric_alarm" "challenge_lambda_errors" {
  alarm_name          = "altcha-challenge-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors challenge lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.challenge.function_name
  }

  tags = {
    Name        = "Altcha Challenge Lambda Errors"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

resource "aws_cloudwatch_metric_alarm" "verify_lambda_errors" {
  alarm_name          = "altcha-verify-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors verify lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.verify.function_name
  }

  tags = {
    Name        = "Altcha Verify Lambda Errors"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# CloudWatch Alarms for Lambda Duration
resource "aws_cloudwatch_metric_alarm" "challenge_lambda_duration" {
  alarm_name          = "altcha-challenge-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds
  alarm_description   = "This metric monitors challenge lambda duration"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.challenge.function_name
  }

  tags = {
    Name        = "Altcha Challenge Lambda Duration"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

resource "aws_cloudwatch_metric_alarm" "verify_lambda_duration" {
  alarm_name          = "altcha-verify-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "3000"  # 3 seconds
  alarm_description   = "This metric monitors verify lambda duration"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.verify.function_name
  }

  tags = {
    Name        = "Altcha Verify Lambda Duration"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# CloudWatch Alarms for API Gateway
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  alarm_name          = "altcha-api-gateway-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "This metric monitors API Gateway 4XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.altcha_api.name
  }

  tags = {
    Name        = "Altcha API Gateway 4XX Errors"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "altcha-api-gateway-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.altcha_api.name
  }

  tags = {
    Name        = "Altcha API Gateway 5XX Errors"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "altcha-alerts"

  tags = {
    Name        = "Altcha Alerts"
    Environment = var.environment
    Project     = "altcha-captcha-api"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "altcha_dashboard" {
  dashboard_name = "Altcha-CAPTCHA-API"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.challenge.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.verify.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.altcha_api.name],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."],
            [".", "Latency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "API Gateway Metrics"
          period  = 300
        }
      }
    ]
  })
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "resume-website"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

# Data sources for existing resources
data "aws_s3_bucket" "website" {
  count  = var.use_existing_resources ? 1 : 0
  bucket = var.domain_name
}

data "aws_dynamodb_table" "contact_messages" {
  count = var.use_existing_resources ? 1 : 0
  name  = "contact-messages"
}

data "aws_dynamodb_table" "visits" {
  count = var.use_existing_resources ? 1 : 0
  name  = "visits"
}

data "aws_lambda_function" "contact_handler" {
  count         = var.use_existing_resources ? 1 : 0
  function_name = "contact-handler"
}

data "aws_lambda_function" "visit_handler" {
  count         = var.use_existing_resources ? 1 : 0
  function_name = "visit-handler"
}

data "aws_api_gateway_rest_api" "resume_api" {
  count = var.use_existing_resources ? 1 : 0
  name  = "resume-api"
}

# Create new resources only if not using existing ones
# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  count  = var.use_existing_resources ? 0 : 1
  bucket = var.domain_name
}

resource "aws_s3_bucket_website_configuration" "website" {
  count  = var.use_existing_resources ? 0 : 1
  bucket = aws_s3_bucket.website[0].id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  count  = var.use_existing_resources ? 0 : 1
  bucket = aws_s3_bucket.website[0].id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  count  = var.use_existing_resources ? 0 : 1
  bucket = aws_s3_bucket.website[0].id
  policy = jsonencode({
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website[0].arn}/*"
      }
    ]
  })
}

# DynamoDB Tables
resource "aws_dynamodb_table" "contact_messages" {
  count        = var.use_existing_resources ? 0 : 1
  name         = "contact-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "visits" {
  count        = var.use_existing_resources ? 0 : 1
  name         = "visits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "path"
  attribute {
    name = "path"
    type = "S"
  }
}

# New DynamoDB table for chatbot (always create as it's new)
resource "aws_dynamodb_table" "conversations" {
  name         = "chatbot-conversations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sessionId"
  attribute {
    name = "sessionId"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# IAM Role for Lambda functions (always create/update)
resource "aws_iam_role" "lambda_role" {
  name = "resume-lambda-role"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "resume-lambda-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = [
          var.use_existing_resources ? data.aws_dynamodb_table.contact_messages[0].arn : aws_dynamodb_table.contact_messages[0].arn,
          var.use_existing_resources ? data.aws_dynamodb_table.visits[0].arn : aws_dynamodb_table.visits[0].arn,
          aws_dynamodb_table.conversations.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
        ]
      }
    ]
  })
}

# New Chatbot Lambda Function (always create as it's new)
resource "aws_lambda_function" "chatbot_handler" {
  filename      = "chatbot-handler.zip"
  function_name = "chatbot-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "chatbot-handler.handler"
  runtime       = "nodejs22.x"
  timeout       = 15
  memory_size   = 256
  environment {
    variables = {
      CONVERSATION_TABLE = aws_dynamodb_table.conversations.name
      ALLOWED_ORIGIN     = "https://${var.domain_name}"
    }
  }
}

# Update existing Lambda functions (only if they exist)
resource "aws_lambda_function" "contact_handler" {
  count         = var.use_existing_resources ? 0 : 1
  filename      = "contact-handler.zip"
  function_name = "contact-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "contact-handler.handler"
  runtime       = "nodejs22.x"
  timeout       = 10
  environment {
    variables = {
      TABLE_NAME = var.use_existing_resources ? data.aws_dynamodb_table.contact_messages[0].name : aws_dynamodb_table.contact_messages[0].name
      TO_EMAIL   = var.contact_email
      SES_FROM   = "no-reply@${var.domain_name}"
    }
  }
}

resource "aws_lambda_function" "visit_handler" {
  count         = var.use_existing_resources ? 0 : 1
  filename      = "visit-handler.zip"
  function_name = "visit-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "visit-handler.handler"
  runtime       = "nodejs22.x"
  timeout       = 10
  environment {
    variables = {
      TABLE_NAME = var.use_existing_resources ? data.aws_dynamodb_table.visits[0].name : aws_dynamodb_table.visits[0].name
    }
  }
}

# Locals for resource references
locals {
  api_gateway_id = var.use_existing_resources ? data.aws_api_gateway_rest_api.resume_api[0].id : aws_api_gateway_rest_api.resume_api[0].id
  contact_function_name = var.use_existing_resources ? data.aws_lambda_function.contact_handler[0].function_name : aws_lambda_function.contact_handler[0].function_name
  visit_function_name = var.use_existing_resources ? data.aws_lambda_function.visit_handler[0].function_name : aws_lambda_function.visit_handler[0].function_name
}

# API Gateway (create only if not existing)
resource "aws_api_gateway_rest_api" "resume_api" {
  count = var.use_existing_resources ? 0 : 1
  name  = "resume-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Add chatbot resource to existing API Gateway
resource "aws_api_gateway_resource" "chatbot" {
  rest_api_id = local.api_gateway_id
  parent_id   = var.use_existing_resources ? data.aws_api_gateway_rest_api.resume_api[0].root_resource_id : aws_api_gateway_rest_api.resume_api[0].root_resource_id
  path_part   = "chatbot"
}

resource "aws_api_gateway_method" "chatbot_post" {
  rest_api_id   = local.api_gateway_id
  resource_id   = aws_api_gateway_resource.chatbot.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "chatbot_options" {
  rest_api_id   = local.api_gateway_id
  resource_id   = aws_api_gateway_resource.chatbot.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "chatbot_post" {
  rest_api_id = local.api_gateway_id
  resource_id = aws_api_gateway_resource.chatbot.id
  http_method = aws_api_gateway_method.chatbot_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chatbot_handler.invoke_arn
}

resource "aws_api_gateway_integration" "chatbot_options" {
  rest_api_id = local.api_gateway_id
  resource_id = aws_api_gateway_resource.chatbot.id
  http_method = aws_api_gateway_method.chatbot_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "chatbot_options" {
  rest_api_id = local.api_gateway_id
  resource_id = aws_api_gateway_resource.chatbot.id
  http_method = aws_api_gateway_method.chatbot_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "chatbot_options" {
  rest_api_id = local.api_gateway_id
  resource_id = aws_api_gateway_resource.chatbot.id
  http_method = aws_api_gateway_method.chatbot_options.http_method
  status_code = aws_api_gateway_method_response.chatbot_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda permission for chatbot
resource "aws_lambda_permission" "chatbot_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:*:${local.api_gateway_id}/*/*"
}

# API Gateway Deployment (update existing)
resource "aws_api_gateway_deployment" "resume_api" {
  depends_on = [
    aws_api_gateway_integration.chatbot_post,
    aws_api_gateway_integration.chatbot_options
  ]
  rest_api_id = local.api_gateway_id
  stage_name  = "prod"
  
  # Force new deployment
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.chatbot.id,
      aws_api_gateway_method.chatbot_post.id,
      aws_api_gateway_integration.chatbot_post.id,
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

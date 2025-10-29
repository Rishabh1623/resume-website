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

# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.domain_name
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# DynamoDB Tables
resource "aws_dynamodb_table" "contact_messages" {
  name         = "contact-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "visits" {
  name         = "visits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "path"
  attribute {
    name = "path"
    type = "S"
  }
}

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

# IAM Role for Lambda functions
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
          aws_dynamodb_table.contact_messages.arn,
          aws_dynamodb_table.visits.arn,
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

# Lambda Functions
resource "aws_lambda_function" "contact_handler" {
  filename      = "contact-handler.zip"
  function_name = "contact-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "contact-handler.handler"
  runtime       = "nodejs22.x"
  timeout       = 10
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.contact_messages.name
      TO_EMAIL   = var.contact_email
      SES_FROM   = "no-reply@${var.domain_name}"
    }
  }
}

resource "aws_lambda_function" "visit_handler" {
  filename      = "visit-handler.zip"
  function_name = "visit-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "visit-handler.handler"
  runtime       = "nodejs22.x"
  timeout       = 10
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visits.name
    }
  }
}

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

# API Gateway
resource "aws_api_gateway_rest_api" "resume_api" {
  name = "resume-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Resources
resource "aws_api_gateway_resource" "contact" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_resource" "visit" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "visit"
}

resource "aws_api_gateway_resource" "chatbot" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "chatbot"
}

# API Methods and Integrations
resource "aws_api_gateway_method" "contact_post" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "contact_post" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_handler.invoke_arn
}

resource "aws_api_gateway_method" "visit_post" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.visit.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "visit_post" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  resource_id = aws_api_gateway_resource.visit.id
  http_method = aws_api_gateway_method.visit_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visit_handler.invoke_arn
}

resource "aws_api_gateway_method" "chatbot_post" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.chatbot.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "chatbot_post" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  resource_id = aws_api_gateway_resource.chatbot.id
  http_method = aws_api_gateway_method.chatbot_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chatbot_handler.invoke_arn
}

# Lambda permissions
resource "aws_lambda_permission" "contact_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "visit_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visit_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "chatbot_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "resume_api" {
  depends_on = [
    aws_api_gateway_integration.contact_post,
    aws_api_gateway_integration.visit_post,
    aws_api_gateway_integration.chatbot_post
  ]
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  stage_name  = "prod"
}

# SES Domain Identity
resource "aws_ses_domain_identity" "domain" {
  domain = var.domain_name
}

resource "aws_ses_email_identity" "email" {
  email = var.contact_email
}

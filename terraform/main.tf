# Resume Website - Optimized Terraform Configuration
# Simple deployment: terraform init -> terraform plan -> terraform apply

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "resume-website"
      Environment = "production"
      ManagedBy   = "terraform"
      Owner       = "rishabh-madne"
    }
  }
}

# ============================================
# DATA SOURCES (for existing resources)
# ============================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_s3_bucket" "existing_website" {
  count  = var.use_existing_resources ? 1 : 0
  bucket = var.domain_name
}

data "aws_dynamodb_table" "existing_contact" {
  count = var.use_existing_resources ? 1 : 0
  name  = "contact-messages"
}

data "aws_dynamodb_table" "existing_visits" {
  count = var.use_existing_resources ? 1 : 0
  name  = "visits"
}

data "aws_api_gateway_rest_api" "existing_api" {
  count = var.use_existing_resources ? 1 : 0
  name  = "resume-api"
}

# ============================================
# LOCALS
# ============================================

locals {
  api_id      = var.use_existing_resources ? data.aws_api_gateway_rest_api.existing_api[0].id : aws_api_gateway_rest_api.main[0].id
  api_root_id = var.use_existing_resources ? data.aws_api_gateway_rest_api.existing_api[0].root_resource_id : aws_api_gateway_rest_api.main[0].root_resource_id

  contact_table_arn = var.use_existing_resources ? data.aws_dynamodb_table.existing_contact[0].arn : aws_dynamodb_table.contact_messages[0].arn
  visits_table_arn  = var.use_existing_resources ? data.aws_dynamodb_table.existing_visits[0].arn : aws_dynamodb_table.visits[0].arn

  lambda_runtime = "nodejs20.x" # Using LTS version
}

# ============================================
# S3 BUCKET (only if new deployment)
# ============================================

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

  error_document {
    key = "index.html"
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
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website[0].arn}/*"
    }]
  })
}

# ============================================
# DYNAMODB TABLES
# ============================================

resource "aws_dynamodb_table" "contact_messages" {
  count        = var.use_existing_resources ? 0 : 1
  name         = "contact-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
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

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
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

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

# ============================================
# IAM ROLE & POLICIES
# ============================================

resource "aws_iam_role" "lambda" {
  name = "resume-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom" {
  name = "resume-lambda-custom-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          local.contact_table_arn,
          local.visits_table_arn,
          aws_dynamodb_table.conversations.arn
        ]
      },
      {
        Sid    = "SESAccess"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress" = "no-reply@${var.domain_name}"
          }
        }
      },
      {
        Sid      = "BedrockAccess"
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
      }
    ]
  })
}

# ============================================
# LAMBDA FUNCTIONS
# ============================================

resource "aws_lambda_function" "contact_handler" {
  count         = var.use_existing_resources ? 0 : 1
  filename      = "${path.module}/../contact-handler.zip"
  function_name = "contact-handler"
  role          = aws_iam_role.lambda.arn
  handler       = "contact-handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 10
  memory_size   = 128

  source_code_hash = filebase64sha256("${path.module}/../contact-handler.zip")

  environment {
    variables = {
      TABLE_NAME = var.use_existing_resources ? data.aws_dynamodb_table.existing_contact[0].name : aws_dynamodb_table.contact_messages[0].name
      TO_EMAIL   = var.contact_email
      SES_FROM   = "no-reply@${var.domain_name}"
    }
  }
}

resource "aws_lambda_function" "visit_handler" {
  count         = var.use_existing_resources ? 0 : 1
  filename      = "${path.module}/../visit-handler.zip"
  function_name = "visit-handler"
  role          = aws_iam_role.lambda.arn
  handler       = "visit-handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 5
  memory_size   = 128

  source_code_hash = filebase64sha256("${path.module}/../visit-handler.zip")

  environment {
    variables = {
      TABLE_NAME = var.use_existing_resources ? data.aws_dynamodb_table.existing_visits[0].name : aws_dynamodb_table.visits[0].name
    }
  }
}

resource "aws_lambda_function" "chatbot_handler" {
  filename      = "${path.module}/../chatbot-handler.zip"
  function_name = "chatbot-handler"
  role          = aws_iam_role.lambda.arn
  handler       = "chatbot-handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 15
  memory_size   = 256

  source_code_hash = filebase64sha256("${path.module}/../chatbot-handler.zip")

  environment {
    variables = {
      CONVERSATION_TABLE = aws_dynamodb_table.conversations.name
      ALLOWED_ORIGIN     = "https://${var.domain_name}"
    }
  }
}

# ============================================
# API GATEWAY
# ============================================

resource "aws_api_gateway_rest_api" "main" {
  count = var.use_existing_resources ? 0 : 1
  name  = "resume-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Chatbot Resource
resource "aws_api_gateway_resource" "chatbot" {
  rest_api_id = local.api_id
  parent_id   = local.api_root_id
  path_part   = "chatbot"
}

resource "aws_api_gateway_method" "chatbot_post" {
  rest_api_id   = local.api_id
  resource_id   = aws_api_gateway_resource.chatbot.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "chatbot_post" {
  rest_api_id             = local.api_id
  resource_id             = aws_api_gateway_resource.chatbot.id
  http_method             = aws_api_gateway_method.chatbot_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chatbot_handler.invoke_arn
}

# Lambda Permission
resource "aws_lambda_permission" "chatbot_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.api_id}/*/*"
}

# API Deployment
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = local.api_id
  stage_name    = "prod"

  xray_tracing_enabled = false
  
  # CloudWatch logging disabled to avoid role ARN requirement
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = local.api_id

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

  depends_on = [
    aws_api_gateway_integration.chatbot_post
  ]
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/resume-api"
  retention_in_days = 7
}

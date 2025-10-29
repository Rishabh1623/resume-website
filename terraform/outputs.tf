# Optimized Outputs

output "website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}

output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = "https://${local.api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
}

output "chatbot_endpoint" {
  description = "Chatbot API endpoint"
  value       = "https://${local.api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod/chatbot"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = local.api_id
}

output "lambda_functions" {
  description = "Lambda function names"
  value = {
    chatbot = aws_lambda_function.chatbot_handler.function_name
  }
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    conversations = aws_dynamodb_table.conversations.name
  }
}

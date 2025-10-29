output "website_url" {
  description = "Website URL"
  value       = "https://${aws_s3_bucket.website.bucket}"
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod"
}

output "contact_endpoint" {
  description = "Contact form endpoint"
  value       = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/contact"
}

output "visit_endpoint" {
  description = "Visit counter endpoint"
  value       = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/visit"
}

output "chatbot_endpoint" {
  description = "Chatbot endpoint"
  value       = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/chatbot"
}

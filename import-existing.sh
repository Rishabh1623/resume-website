#!/bin/bash

set -e

echo "📥 Importing Existing AWS Resources into Terraform..."

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found."
    exit 1
fi

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured."
    exit 1
fi

cd terraform

# Initialize Terraform
terraform init

# Get resource details
DOMAIN_NAME=$(grep 'domain_name' terraform.tfvars | cut -d'"' -f2)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "🔍 Importing resources for domain: $DOMAIN_NAME"

# Import S3 bucket
echo "📦 Importing S3 bucket..."
if aws s3api head-bucket --bucket "$DOMAIN_NAME" 2>/dev/null; then
    terraform import 'aws_s3_bucket.website[0]' "$DOMAIN_NAME" || echo "⚠️  S3 bucket import failed (may already be imported)"
fi

# Import DynamoDB tables
echo "🗄️  Importing DynamoDB tables..."
if aws dynamodb describe-table --table-name contact-messages 2>/dev/null; then
    terraform import 'aws_dynamodb_table.contact_messages[0]' "contact-messages" || echo "⚠️  contact-messages import failed"
fi

if aws dynamodb describe-table --table-name visits 2>/dev/null; then
    terraform import 'aws_dynamodb_table.visits[0]' "visits" || echo "⚠️  visits import failed"
fi

# Import Lambda functions
echo "⚡ Importing Lambda functions..."
if aws lambda get-function --function-name contact-handler 2>/dev/null; then
    terraform import 'aws_lambda_function.contact_handler[0]' "contact-handler" || echo "⚠️  contact-handler import failed"
fi

if aws lambda get-function --function-name visit-handler 2>/dev/null; then
    terraform import 'aws_lambda_function.visit_handler[0]' "visit-handler" || echo "⚠️  visit-handler import failed"
fi

# Import IAM role
echo "🔐 Importing IAM role..."
if aws iam get-role --role-name resume-lambda-role 2>/dev/null; then
    terraform import aws_iam_role.lambda_role "resume-lambda-role" || echo "⚠️  IAM role import failed"
fi

# Import API Gateway
echo "🌐 Importing API Gateway..."
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
if [ "$API_ID" != "None" ] && [ -n "$API_ID" ]; then
    terraform import 'aws_api_gateway_rest_api.resume_api[0]' "$API_ID" || echo "⚠️  API Gateway import failed"
fi

echo ""
echo "✅ Import process completed!"
echo "⚠️  Some imports may have failed if resources don't exist or are already imported."
echo ""
echo "📋 Next steps:"
echo "1. Run: terraform plan -var='use_existing_resources=true'"
echo "2. Review the plan to ensure no conflicts"
echo "3. Run: terraform apply -var='use_existing_resources=true'"

cd ..

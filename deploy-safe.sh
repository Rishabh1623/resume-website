#!/bin/bash

set -e

echo "🚀 Safe Deployment - Adding Chatbot to Existing Infrastructure..."

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform."
    exit 1
fi

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure'"
    exit 1
fi

# Check for existing resources
echo "🔍 Checking existing AWS resources..."

# Check if S3 bucket exists
DOMAIN_NAME=$(grep 'domain_name' terraform/terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "")
if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Please create terraform/terraform.tfvars with your domain_name"
    exit 1
fi

BUCKET_EXISTS=$(aws s3api head-bucket --bucket "$DOMAIN_NAME" 2>/dev/null && echo "true" || echo "false")
LAMBDA_EXISTS=$(aws lambda get-function --function-name contact-handler 2>/dev/null && echo "true" || echo "false")
API_EXISTS=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text 2>/dev/null | grep -v "None" && echo "true" || echo "false")

echo "📊 Resource Status:"
echo "   S3 Bucket ($DOMAIN_NAME): $BUCKET_EXISTS"
echo "   Lambda Functions: $LAMBDA_EXISTS" 
echo "   API Gateway: $API_EXISTS"

# Determine deployment strategy
if [ "$BUCKET_EXISTS" = "true" ] || [ "$LAMBDA_EXISTS" = "true" ] || [ "$API_EXISTS" = "true" ]; then
    echo "✅ Existing resources detected. Using safe import mode."
    USE_EXISTING="true"
    
    # Use import-friendly configuration
    cp terraform/main-import.tf terraform/main.tf
    cp terraform/variables-import.tf terraform/variables.tf
else
    echo "✅ No existing resources found. Creating fresh infrastructure."
    USE_EXISTING="false"
fi

# Package Lambda functions
echo "📦 Packaging Lambda functions..."
cd lambda
zip -q ../contact-handler.zip contact-handler.mjs
zip -q ../visit-handler.zip visit-handler.mjs  
zip -q ../chatbot-handler.zip chatbot-handler.mjs
cd ..

# Deploy infrastructure
echo "🏗️  Deploying infrastructure..."
cd terraform

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found. Please copy terraform.tfvars.example and update values."
    exit 1
fi

# Add use_existing_resources to tfvars if not present
if ! grep -q "use_existing_resources" terraform.tfvars; then
    echo "use_existing_resources = $USE_EXISTING" >> terraform.tfvars
fi

# Initialize Terraform
terraform init

# Plan with existing resources
echo "📋 Planning deployment..."
terraform plan -var="use_existing_resources=$USE_EXISTING"

# Ask for confirmation
read -p "🤔 Do you want to proceed with this plan? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Apply changes
terraform apply -var="use_existing_resources=$USE_EXISTING" -auto-approve

# Get API Gateway URL
if [ "$USE_EXISTING" = "true" ]; then
    API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
else
    API_ID=$(terraform output -raw api_gateway_url | cut -d'/' -f3 | cut -d'.' -f1)
fi

API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"

cd ..

# Update website with API URL
echo "🌐 Updating website configuration..."
sed -i.bak "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html

# Deploy website to S3
echo "📤 Uploading website to S3..."
aws s3 sync website/ s3://${DOMAIN_NAME} --delete

# Restore original HTML
mv website/index.html.bak website/index.html

# Test new chatbot endpoint
echo "🧪 Testing chatbot endpoint..."
if curl -f "${API_URL}/chatbot" -X POST -H "Content-Type: application/json" -d '{"message":"test","sessionId":"deploy-test"}' > /dev/null 2>&1; then
    echo "✅ Chatbot endpoint working"
else
    echo "⚠️  Chatbot endpoint test failed (may need a few minutes to propagate)"
fi

echo ""
echo "🎉 Safe deployment completed!"
echo "🔗 Website URL: https://${DOMAIN_NAME}"
echo "🔗 API Gateway URL: ${API_URL}"
echo "🤖 Chatbot endpoint: ${API_URL}/chatbot"
echo ""
echo "📋 What was deployed:"
if [ "$USE_EXISTING" = "true" ]; then
    echo "✅ Used existing S3, Lambda, and API Gateway"
    echo "✅ Added new chatbot functionality"
    echo "✅ Created chatbot-conversations DynamoDB table"
    echo "✅ Updated IAM permissions for Bedrock"
else
    echo "✅ Created complete new infrastructure"
    echo "✅ All resources created fresh"
fi
echo ""
echo "💰 Additional monthly cost: ~$1-3 for chatbot (Claude 3 Haiku)"

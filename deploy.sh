#!/bin/bash

set -e

echo "🚀 Deploying Resume Website with Bedrock Chatbot..."

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform."
    exit 1
fi

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure'"
    exit 1
fi

# Check Bedrock access
echo "🔍 Checking Bedrock model access..."
if ! aws bedrock list-foundation-models --region us-east-1 > /dev/null 2>&1; then
    echo "⚠️  Please request access to Claude 3 Haiku in Bedrock console"
    echo "   Go to: AWS Console > Bedrock > Model access > Request access"
    exit 1
fi

# Package Lambda functions
echo "📦 Packaging Lambda functions..."
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs  
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..

# Deploy infrastructure
echo "🏗️  Deploying infrastructure..."
cd terraform

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found. Please copy terraform.tfvars.example and update values."
    exit 1
fi

# Initialize and apply
terraform init
terraform plan
terraform apply -auto-approve

# Get outputs
API_URL=$(terraform output -raw api_gateway_url)
WEBSITE_URL=$(terraform output -raw website_url)

cd ..

# Deploy website
echo "🌐 Deploying website..."
DOMAIN_NAME=$(grep 'domain_name' terraform/terraform.tfvars | cut -d'"' -f2)

# Update API URLs in HTML
sed -i "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html

# Upload to S3
aws s3 sync website/ s3://${DOMAIN_NAME} --delete

# Test endpoints
echo "🧪 Testing endpoints..."
curl -f "${API_URL}/visit" -X POST > /dev/null && echo "✅ Visit endpoint working"
curl -f "${API_URL}/chatbot" -X POST -H "Content-Type: application/json" -d '{"message":"test","sessionId":"deploy-test"}' > /dev/null && echo "✅ Chatbot endpoint working"

echo ""
echo "🎉 Deployment completed successfully!"
echo "🔗 Website URL: ${WEBSITE_URL}"
echo "🔗 API Gateway URL: ${API_URL}"
echo ""
echo "📋 Next Steps:"
echo "1. Configure your domain DNS to point to S3"
echo "2. Verify SES email address in AWS Console"
echo "3. Test the contact form and chatbot"
echo ""
echo "💰 Expected monthly cost: ~$5-7 for moderate usage"

# Deployment Guide

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (>= 1.0)
3. **AWS CLI** configured with credentials
4. **Bedrock Model Access** - Request access to Claude 3 Haiku in AWS Console

## Quick Deployment

### 1. Configure Variables
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy Everything
```bash
./deploy.sh
```

## Manual Deployment

### 1. Package Lambda Functions
```bash
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..
```

### 2. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
cd ..
```

### 3. Deploy Website
```bash
# Get API Gateway URL from Terraform outputs
API_URL=$(cd terraform && terraform output -raw api_gateway_url)

# Update HTML with API URLs
sed -i "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html

# Upload to S3
aws s3 sync website/ s3://yourdomain.com --delete
```

## Post-Deployment

### 1. Verify SES Email
- Go to AWS Console > SES
- Verify your contact email address
- Test email sending

### 2. Request Bedrock Access
- Go to AWS Console > Bedrock > Model access
- Request access to Claude 3 Haiku
- Wait for approval (usually instant)

### 3. Test Functionality
- Visit your website
- Test contact form
- Test chatbot
- Check visit counter

## Troubleshooting

### Common Issues

**Bedrock Access Denied**
```bash
# Check model access
aws bedrock list-foundation-models --region us-east-1
```

**Lambda Function Errors**
```bash
# Check logs
aws logs tail /aws/lambda/chatbot-handler --follow
```

**CORS Errors**
- Ensure API Gateway has proper CORS configuration
- Check browser developer tools for specific errors

### Cost Monitoring
- Set up billing alerts in AWS Console
- Monitor CloudWatch metrics
- Review monthly AWS bills

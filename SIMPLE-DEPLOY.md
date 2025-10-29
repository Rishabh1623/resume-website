# Simple Deployment Guide

## Quick Start - Just 3 Commands!

### 1. Package Lambda Functions
```bash
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..
```

### 2. Deploy with Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Update Website
```bash
# Get API URL
cd terraform
API_ID=$(terraform output -raw api_gateway_id)
cd ..

# Update HTML
sed -i "s|YOUR_API_GATEWAY_URL|https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod|g" website/index.html

# Upload to S3
aws s3 sync website/ s3://rishabhmadne.com --delete
```

That's it! Your website with AI chatbot is deployed.

---

## Prerequisites

Make sure you have:
- AWS CLI configured (`aws configure`)
- Terraform installed
- zip utility installed

---

## Configuration File

Create `terraform/terraform.tfvars`:
```hcl
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
```

---

## What Gets Deployed

### New Resources (Always Created):
- Lambda: `chatbot-handler`
- DynamoDB: `chatbot-conversations`
- API Gateway endpoint: `/chatbot`

### Existing Resources (Reused if `use_existing_resources = true`):
- S3 bucket: `rishabhmadne.com`
- Lambda: `contact-handler`, `visit-handler`
- DynamoDB: `contact-messages`, `visits`
- API Gateway: `resume-api`

---

## Troubleshooting

### Issue: Bedrock Access Denied
```bash
# Request access in AWS Console
# Go to: Bedrock → Model access → Request access to Claude 3 Haiku
```

### Issue: Terraform State Issues
```bash
cd terraform
terraform state list
terraform refresh
```

### Issue: Lambda Not Updating
```bash
# Delete and recreate
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform apply
```

---

## Verify Deployment

```bash
# Test chatbot endpoint
API_ID=$(cd terraform && terraform output -raw api_gateway_id)
curl -X POST "https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","sessionId":"test"}'

# Check website
curl https://rishabhmadne.com
```

---

## Clean Up (Optional)

To remove only the chatbot:
```bash
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations
```

To remove everything:
```bash
cd terraform
terraform destroy
```

---

## Cost Estimate

- **Chatbot**: ~$1-3/month
- **Lambda**: ~$0.50/month
- **DynamoDB**: ~$0.50/month
- **API Gateway**: ~$3.50/month
- **Total**: ~$3-5/month

# 🚀 Complete Deployment Guide - Step by Step

## Overview
This guide will take you from zero to a fully deployed AI-powered portfolio website on AWS.

**Time Required**: 30-45 minutes  
**Cost**: ~$3-5/month  
**Prerequisites**: AWS account, basic terminal knowledge

---

## 📋 Table of Contents
1. [Prerequisites Setup](#1-prerequisites-setup)
2. [AWS Configuration](#2-aws-configuration)
3. [Clone Repository](#3-clone-repository)
4. [Configure Project](#4-configure-project)
5. [Package Lambda Functions](#5-package-lambda-functions)
6. [Deploy Infrastructure](#6-deploy-infrastructure)
7. [Update Website](#7-update-website)
8. [Verify Deployment](#8-verify-deployment)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites Setup

### Option A: Deploy from EC2 Instance (Recommended)

#### Step 1.1: Connect to EC2
```bash
# If you have SSH key
ssh -i "your-key.pem" ubuntu@your-ec2-ip

# Or use AWS Console → EC2 → Connect (browser-based)
```

#### Step 1.2: Install Required Tools
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install AWS CLI
sudo apt install awscli -y

# Verify AWS CLI
aws --version

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform -y

# Verify Terraform
terraform --version

# Install zip utility
sudo apt install zip -y

# Install git (if not already installed)
sudo apt install git -y
```

### Option B: Deploy from Local Machine (Windows/Mac/Linux)

#### For Windows:
1. Install [AWS CLI](https://aws.amazon.com/cli/)
2. Install [Terraform](https://www.terraform.io/downloads)
3. Install [Git](https://git-scm.com/downloads)
4. Use PowerShell or Git Bash

#### For Mac:
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install awscli terraform git
```

#### For Linux:
```bash
# Follow EC2 instructions above
```

---

## 2. AWS Configuration

### Step 2.1: Create IAM User (If needed)

1. Go to AWS Console → IAM → Users → Add User
2. User name: `terraform-deploy`
3. Access type: ✅ Programmatic access
4. Permissions: Attach existing policies:
   - `AdministratorAccess` (for initial setup)
   - Or create custom policy (see below)
5. Save Access Key ID and Secret Access Key

**Custom Policy (More Secure)**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "lambda:*",
        "apigateway:*",
        "dynamodb:*",
        "iam:*",
        "logs:*",
        "bedrock:InvokeModel",
        "ses:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step 2.2: Configure AWS CLI
```bash
aws configure
```

Enter:
- **AWS Access Key ID**: [Your key from Step 2.1]
- **AWS Secret Access Key**: [Your secret from Step 2.1]
- **Default region name**: `us-east-1`
- **Default output format**: `json`

### Step 2.3: Verify AWS Configuration
```bash
# Test AWS credentials
aws sts get-caller-identity

# Should output:
# {
#     "UserId": "AIDAXXXXXXXXXX",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/terraform-deploy"
# }
```

### Step 2.4: Request Bedrock Model Access

1. Go to AWS Console → Amazon Bedrock
2. Click "Model access" in left sidebar
3. Click "Request model access"
4. Find "Claude 3 Haiku" by Anthropic
5. Click "Request access"
6. Wait for approval (usually instant)

**Verify access**:
```bash
aws bedrock list-foundation-models --region us-east-1 | grep claude-3-haiku
```

### Step 2.5: Verify SES Email (For Contact Form)

1. Go to AWS Console → Amazon SES
2. Click "Verified identities"
3. Click "Create identity"
4. Select "Email address"
5. Enter: `rishabhmadne16@outlook.com`
6. Click "Create identity"
7. Check your email and click verification link

**Verify**:
```bash
aws ses list-verified-email-addresses
```

---

## 3. Clone Repository

### Step 3.1: Clone from GitHub
```bash
# Navigate to home directory
cd ~

# Clone repository
git clone https://github.com/Rishabh1623/resume-website.git

# Navigate into project
cd resume-website

# Verify files
ls -la
```

**Expected output**:
```
drwxr-xr-x  docs/
drwxr-xr-x  lambda/
drwxr-xr-x  terraform/
drwxr-xr-x  website/
-rw-r--r--  README.md
-rw-r--r--  QUICK-START.md
-rwxr-xr-x  deploy-optimized.sh
...
```

---

## 4. Configure Project

### Step 4.1: Create terraform.tfvars
```bash
cat > terraform/terraform.tfvars << 'EOF'
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
EOF
```

### Step 4.2: Verify Configuration
```bash
cat terraform/terraform.tfvars
```

**Should show**:
```
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
```

### Step 4.3: Choose Chatbot Version

**Option A: Use Advanced Chatbot (Recommended)**
```bash
# Copy advanced version
cp lambda/chatbot-handler-advanced.mjs lambda/chatbot-handler.mjs
```

**Option B: Use Optimized Chatbot**
```bash
# Copy optimized version
cp lambda/chatbot-handler-optimized.mjs lambda/chatbot-handler.mjs
```

**Option C: Use Basic Chatbot**
```bash
# Already in place, no action needed
```

---

## 5. Package Lambda Functions

### Step 5.1: Create ZIP Files
```bash
# Navigate to lambda directory
cd lambda

# Package contact handler
zip ../contact-handler.zip contact-handler.mjs

# Package visit handler
zip ../visit-handler.zip visit-handler.mjs

# Package chatbot handler
zip ../chatbot-handler.zip chatbot-handler.mjs

# Return to project root
cd ..
```

### Step 5.2: Verify ZIP Files
```bash
ls -lh *.zip
```

**Expected output**:
```
-rw-r--r-- 1 ubuntu ubuntu 2.1K chatbot-handler.zip
-rw-r--r-- 1 ubuntu ubuntu 1.2K contact-handler.zip
-rw-r--r-- 1 ubuntu ubuntu  800 visit-handler.zip
```

---

## 6. Deploy Infrastructure

### Step 6.1: Initialize Terraform
```bash
cd terraform
terraform init
```

**Expected output**:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 6.2: Validate Configuration
```bash
terraform validate
```

**Expected output**:
```
Success! The configuration is valid.
```

### Step 6.3: Format Terraform Files
```bash
terraform fmt
```

### Step 6.4: Plan Deployment
```bash
terraform plan -out=tfplan
```

**Review the plan carefully!**

Look for:
- ✅ **Creating** new resources (chatbot Lambda, DynamoDB table)
- ✅ **Using** existing resources (S3, API Gateway)
- ❌ **NOT destroying** existing resources

**Expected resources to create**:
```
Plan: 8 to add, 0 to change, 0 to destroy.

Resources to be created:
  + aws_lambda_function.chatbot_handler
  + aws_dynamodb_table.conversations
  + aws_api_gateway_resource.chatbot
  + aws_api_gateway_method.chatbot_post
  + aws_api_gateway_integration.chatbot_post
  + aws_lambda_permission.chatbot_api
  + aws_api_gateway_deployment.main
  + aws_cloudwatch_log_group.api_gateway
```

### Step 6.5: Apply Configuration
```bash
terraform apply tfplan
```

**This will**:
- Create chatbot Lambda function
- Create DynamoDB table for conversations
- Add /chatbot endpoint to API Gateway
- Set up IAM permissions
- Configure CloudWatch logging

**Wait for completion** (2-3 minutes)

**Expected output**:
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

api_gateway_id = "abc123xyz"
api_gateway_url = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod"
chatbot_endpoint = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/chatbot"
website_url = "https://rishabhmadne.com"
```

### Step 6.6: Save Outputs
```bash
# Save API Gateway ID
API_ID=$(terraform output -raw api_gateway_id)
echo "API Gateway ID: $API_ID"

# Save API URL
API_URL=$(terraform output -raw api_gateway_url)
echo "API URL: $API_URL"

# Return to project root
cd ..
```

---

## 7. Update Website

### Step 7.1: Update HTML with API URL
```bash
# Get API URL
API_ID=$(cd terraform && terraform output -raw api_gateway_id)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"

echo "Updating website with API URL: $API_URL"

# Update index.html
sed -i.bak "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html

# Verify update
grep "execute-api" website/index.html
```

### Step 7.2: Upload to S3
```bash
# Sync website to S3
aws s3 sync website/ s3://rishabhmadne.com --delete

# Set cache control
aws s3 sync website/ s3://rishabhmadne.com \
  --cache-control "max-age=300" \
  --delete
```

**Expected output**:
```
upload: website/index.html to s3://rishabhmadne.com/index.html
upload: website/chatbot-enhanced.js to s3://rishabhmadne.com/chatbot-enhanced.js
```

### Step 7.3: Restore Original HTML (Optional)
```bash
# Restore backup (keeps YOUR_API_GATEWAY_URL for future deployments)
mv website/index.html.bak website/index.html
```

---

## 8. Verify Deployment

### Step 8.1: Test Chatbot Endpoint
```bash
# Get API URL
API_URL=$(cd terraform && terraform output -raw api_gateway_url)

# Test chatbot
curl -X POST "${API_URL}/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, tell me about your AWS experience","sessionId":"test-123"}'
```

**Expected response**:
```json
{
  "response": "I have 4+ years of AWS experience...",
  "actions": [],
  "suggestions": ["What projects have you built?", "Tell me about your certifications"],
  "sessionId": "test-123"
}
```

### Step 8.2: Test Visit Counter
```bash
curl -X POST "${API_URL}/visit"
```

**Expected response**:
```json
{
  "visitCount": 1,
  "timestamp": "2025-01-29T10:30:00.000Z"
}
```

### Step 8.3: Check Website
```bash
# Test website is accessible
curl -I https://rishabhmadne.com

# Should return: HTTP/1.1 200 OK
```

### Step 8.4: Open in Browser
```
https://rishabhmadne.com
```

**Verify**:
- ✅ Website loads
- ✅ Chatbot widget appears (bottom-right)
- ✅ Chatbot responds to messages
- ✅ Visit counter updates
- ✅ Contact form works

### Step 8.5: Check CloudWatch Logs
```bash
# View chatbot logs
aws logs tail /aws/lambda/chatbot-handler --follow

# In another terminal, send a test message
curl -X POST "${API_URL}/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"test","sessionId":"log-test"}'
```

---

## 9. Troubleshooting

### Issue 1: Terraform Init Fails

**Error**: "Failed to download provider"

**Solution**:
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

---

### Issue 2: Bedrock Access Denied

**Error**: "AccessDeniedException: Could not access model"

**Solution**:
```bash
# Check model access
aws bedrock list-foundation-models --region us-east-1 | grep claude

# If not listed, request access:
# AWS Console → Bedrock → Model access → Request access
```

---

### Issue 3: Lambda Deployment Fails

**Error**: "Error creating Lambda function"

**Solution**:
```bash
# Check ZIP file exists
ls -lh chatbot-handler.zip

# Verify IAM permissions
aws iam get-role --role-name resume-lambda-role

# Check Lambda logs
aws logs tail /aws/lambda/chatbot-handler --follow
```

---

### Issue 4: API Gateway Not Working

**Error**: "403 Forbidden" or "404 Not Found"

**Solution**:
```bash
# Check API Gateway exists
aws apigateway get-rest-apis --query "items[?name=='resume-api']"

# Redeploy API Gateway
cd terraform
terraform apply -replace=aws_api_gateway_deployment.main
cd ..

# Test endpoint
curl -X POST "${API_URL}/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"test","sessionId":"debug"}'
```

---

### Issue 5: Website Not Updating

**Error**: Old content still showing

**Solution**:
```bash
# Clear S3 cache
aws s3 sync website/ s3://rishabhmadne.com \
  --delete \
  --cache-control "max-age=0"

# If using CloudFront, invalidate cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"

# Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)
```

---

### Issue 6: DynamoDB Errors

**Error**: "ResourceNotFoundException: Table not found"

**Solution**:
```bash
# Check table exists
aws dynamodb list-tables

# If missing, recreate
cd terraform
terraform apply -target=aws_dynamodb_table.conversations
cd ..
```

---

### Issue 7: High Costs

**Issue**: AWS bill higher than expected

**Solution**:
```bash
# Check costs
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Optimize:
# 1. Reduce Lambda memory (256MB → 128MB)
# 2. Lower max_tokens (500 → 300)
# 3. Shorter TTL (2h → 1h)
# 4. Reduce conversation history (5 → 3)
```

---

### Issue 8: SES Email Not Sending

**Error**: "Email address not verified"

**Solution**:
```bash
# Check verified emails
aws ses list-verified-email-addresses

# Verify email
# AWS Console → SES → Verified identities → Create identity

# Test email
aws ses send-email \
  --from rishabhmadne16@outlook.com \
  --to rishabhmadne16@outlook.com \
  --subject "Test" \
  --text "Test email"
```

---

## 10. Post-Deployment Tasks

### Step 10.1: Set Up Monitoring

**CloudWatch Alarms**:
```bash
# Create alarm for Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name chatbot-errors \
  --alarm-description "Alert on chatbot errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=chatbot-handler
```

### Step 10.2: Set Up Cost Alerts

1. Go to AWS Console → Billing → Budgets
2. Create budget: $10/month
3. Set alert at 80% ($8)
4. Add email notification

### Step 10.3: Enable Backups

```bash
# Enable DynamoDB point-in-time recovery
aws dynamodb update-continuous-backups \
  --table-name chatbot-conversations \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### Step 10.4: Document Your Setup

Create a file with your specific details:
```bash
cat > DEPLOYMENT-INFO.md << 'EOF'
# Deployment Information

## AWS Account
- Account ID: [Your account ID]
- Region: us-east-1
- IAM User: terraform-deploy

## Resources
- S3 Bucket: rishabhmadne.com
- API Gateway ID: [Your API ID]
- Lambda Functions:
  - chatbot-handler
  - contact-handler
  - visit-handler
- DynamoDB Tables:
  - chatbot-conversations
  - contact-messages
  - visits

## URLs
- Website: https://rishabhmadne.com
- API: https://[API-ID].execute-api.us-east-1.amazonaws.com/prod

## Deployment Date
- Initial: [Date]
- Last Update: [Date]

## Costs
- Monthly: ~$3-5
- Per conversation: ~$0.001

## Monitoring
- CloudWatch Logs: /aws/lambda/chatbot-handler
- Metrics: AWS Console → CloudWatch
- Costs: AWS Console → Cost Explorer
EOF
```

---

## 11. Maintenance

### Regular Tasks

**Weekly**:
```bash
# Check logs for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/chatbot-handler \
  --filter-pattern "ERROR" \
  --start-time $(date -d '7 days ago' +%s)000

# Check costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

**Monthly**:
```bash
# Review and optimize
# 1. Check conversation patterns
# 2. Optimize prompts
# 3. Review costs
# 4. Update content
```

### Update Deployment

```bash
# Pull latest changes
cd ~/resume-website
git pull origin main

# Repackage Lambda
cd lambda
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..

# Apply changes
cd terraform
terraform apply
cd ..

# Update website
aws s3 sync website/ s3://rishabhmadne.com --delete
```

---

## 12. Cleanup (If Needed)

### Remove Only Chatbot
```bash
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations
cd ..
```

### Remove Everything
```bash
cd terraform
terraform destroy
cd ..
```

---

## 📞 Support

If you encounter issues:

1. **Check logs**: `aws logs tail /aws/lambda/chatbot-handler --follow`
2. **Review documentation**: `docs/ADVANCED-CHATBOT.md`
3. **Check troubleshooting**: Section 9 above
4. **GitHub Issues**: Create an issue in your repository

---

## ✅ Deployment Checklist

- [ ] AWS CLI configured
- [ ] Terraform installed
- [ ] Bedrock access approved
- [ ] SES email verified
- [ ] Repository cloned
- [ ] terraform.tfvars created
- [ ] Lambda functions packaged
- [ ] Terraform applied successfully
- [ ] Website updated with API URL
- [ ] Website uploaded to S3
- [ ] Chatbot tested and working
- [ ] Visit counter working
- [ ] CloudWatch logs visible
- [ ] Monitoring set up
- [ ] Cost alerts configured
- [ ] Documentation updated

---

## 🎉 Success!

Your AI-powered portfolio website is now live at **https://rishabhmadne.com**

**Next Steps**:
1. Test all features thoroughly
2. Share with recruiters and hiring managers
3. Monitor usage and costs
4. Iterate and improve based on feedback

**Remember**: This chatbot is your differentiator - make sure to highlight it in interviews!

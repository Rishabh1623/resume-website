# 🚀 Deploy Now - Copy & Paste Commands

## Quick Deployment (30 minutes)

Just copy and paste these commands in order. Everything is automated.

---

## Step 1: Connect to EC2
```bash
ssh -i "your-key.pem" ubuntu@your-ec2-ip
```

---

## Step 2: Install Tools (One-time setup)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install AWS CLI
sudo apt install awscli -y

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Install zip and git
sudo apt install zip git -y

# Verify installations
aws --version && terraform --version && git --version
```

---

## Step 3: Configure AWS
```bash
# Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Format (json)

# Verify
aws sts get-caller-identity
```

---

## Step 4: Clone Repository
```bash
cd ~
git clone https://github.com/Rishabh1623/resume-website.git
cd resume-website
```

---

## Step 5: Configure Project
```bash
# Create configuration file
cat > terraform/terraform.tfvars << 'EOF'
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
EOF

# Use advanced chatbot (recommended)
cp lambda/chatbot-handler-advanced.mjs lambda/chatbot-handler.mjs
```

---

## Step 6: Package Lambda Functions
```bash
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..
```

---

## Step 7: Deploy with Terraform
```bash
cd terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
cd ..
```

---

## Step 8: Update Website
```bash
# Get API URL
API_ID=$(cd terraform && terraform output -raw api_gateway_id)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"

# Update HTML
sed -i.bak "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html

# Upload to S3
aws s3 sync website/ s3://rishabhmadne.com --delete

# Restore original
mv website/index.html.bak website/index.html
```

---

## Step 9: Test Deployment
```bash
# Test chatbot
curl -X POST "${API_URL}/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, tell me about your AWS experience","sessionId":"test"}'

# Test visit counter
curl -X POST "${API_URL}/visit"

# Check website
curl -I https://rishabhmadne.com
```

---

## Step 10: View Logs
```bash
# Watch chatbot logs
aws logs tail /aws/lambda/chatbot-handler --follow
```

---

## ✅ Done!

Your website is live at: **https://rishabhmadne.com**

---

## 🔧 Quick Commands

### View Terraform Outputs
```bash
cd ~/resume-website/terraform
terraform output
```

### Update Deployment
```bash
cd ~/resume-website
git pull origin main
cd lambda
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ../terraform
terraform apply
cd ..
aws s3 sync website/ s3://rishabhmadne.com --delete
```

### Check Logs
```bash
# Chatbot logs
aws logs tail /aws/lambda/chatbot-handler --follow

# Contact handler logs
aws logs tail /aws/lambda/contact-handler --follow

# Visit handler logs
aws logs tail /aws/lambda/visit-handler --follow
```

### Check Costs
```bash
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### Destroy Resources
```bash
# Remove only chatbot
cd ~/resume-website/terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations

# Remove everything
terraform destroy
```

---

## 🆘 Troubleshooting

### Bedrock Access Denied
```bash
# Check access
aws bedrock list-foundation-models --region us-east-1 | grep claude

# If not found, go to AWS Console:
# Bedrock → Model access → Request access to Claude 3 Haiku
```

### Lambda Errors
```bash
# Check logs
aws logs tail /aws/lambda/chatbot-handler --follow

# Redeploy
cd ~/resume-website/terraform
terraform apply -replace=aws_lambda_function.chatbot_handler
```

### API Gateway Not Working
```bash
# Redeploy API
cd ~/resume-website/terraform
terraform apply -replace=aws_api_gateway_deployment.main
```

### Website Not Updating
```bash
# Force update
aws s3 sync website/ s3://rishabhmadne.com --delete --cache-control "max-age=0"
```

---

## 📚 Full Documentation

- **Complete Guide**: `COMPLETE-DEPLOYMENT-GUIDE.md`
- **Quick Start**: `QUICK-START.md`
- **Chatbot Details**: `docs/ADVANCED-CHATBOT.md`
- **Troubleshooting**: `COMPLETE-DEPLOYMENT-GUIDE.md` Section 9

---

## 💡 Before You Start

Make sure you have:
- [ ] AWS account with admin access
- [ ] Access Key and Secret Key
- [ ] Bedrock access approved (Claude 3 Haiku)
- [ ] SES email verified (rishabhmadne16@outlook.com)
- [ ] EC2 instance or local terminal ready

---

## ⏱️ Time Estimate

- **First-time setup**: 30-45 minutes
- **Subsequent deployments**: 5-10 minutes

---

## 💰 Cost Estimate

- **Monthly**: $3-5
- **Per conversation**: $0.001
- **3000 conversations/month**: ~$3

---

## 🎯 What Gets Deployed

### New Resources
- ✅ Lambda: chatbot-handler
- ✅ DynamoDB: chatbot-conversations
- ✅ API Gateway: /chatbot endpoint
- ✅ CloudWatch: Log groups
- ✅ IAM: Permissions for Bedrock

### Existing Resources (Reused)
- ✅ S3: rishabhmadne.com
- ✅ Lambda: contact-handler, visit-handler
- ✅ DynamoDB: contact-messages, visits
- ✅ API Gateway: resume-api

---

## 🚀 Ready to Deploy?

1. Open terminal
2. Copy commands from Step 1
3. Paste and execute
4. Continue through all steps
5. Test your website!

**Good luck! 🎉**

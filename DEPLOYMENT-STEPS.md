# Deployment Steps from EC2 Instance

## 1. Push Changes to GitHub (From Windows)

```bash
git push origin main
```

## 2. Connect to Your EC2 Instance

```bash
ssh -i "your-key.pem" ubuntu@your-ec2-ip
```
Or use AWS Console → EC2 → Connect (browser-based)

---

## 3. Install Prerequisites (One-time setup)

### Check if already installed:
```bash
terraform --version
aws --version
zip --version
```

### If not installed, run:
```bash
# Update system
sudo apt update

# Install AWS CLI
sudo apt install awscli -y

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Install zip utility
sudo apt install zip -y

# Install git (if needed)
sudo apt install git -y
```

---

## 4. Configure AWS Credentials

```bash
aws configure
```
Enter:
- AWS Access Key ID: [Your key]
- AWS Secret Access Key: [Your secret]
- Region: `us-east-1`
- Output format: `json`

**Verify configuration:**
```bash
aws sts get-caller-identity
```

---

## 5. Clone Repository

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/resume-website.git
cd resume-website
```

**Or if already cloned, pull latest changes:**
```bash
cd ~/resume-website
git pull origin main
```

---

## 6. Create terraform.tfvars

```bash
cat > terraform/terraform.tfvars << 'EOF'
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
EOF
```

**Verify the file:**
```bash
cat terraform/terraform.tfvars
```

---

## 7. Manual Terraform Deployment (Step-by-Step)

### Option A: Using deploy-safe.sh script
```bash
chmod +x deploy-safe.sh
./deploy-safe.sh
```

### Option B: Manual Terraform commands

#### Step 1: Package Lambda functions
```bash
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..
```

#### Step 2: Verify zip files created
```bash
ls -lh *.zip
```

#### Step 3: Copy import configuration (for existing resources)
```bash
cp terraform/main-import.tf terraform/main.tf
cp terraform/variables-import.tf terraform/variables.tf
```

#### Step 4: Initialize Terraform
```bash
cd terraform
terraform init
```

#### Step 5: Validate configuration
```bash
terraform validate
```

#### Step 6: Plan deployment
```bash
terraform plan -var="use_existing_resources=true"
```
**Review the plan carefully!** It should show:
- ✅ Creating new chatbot resources
- ✅ Using existing S3, Lambda, API Gateway
- ❌ Should NOT destroy or recreate existing resources

#### Step 7: Apply changes
```bash
terraform apply -var="use_existing_resources=true"
```
Type `yes` when prompted.

#### Step 8: Get API Gateway URL
```bash
terraform output
```
Or:
```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
echo "API URL: https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
```

#### Step 9: Update website with API URL
```bash
cd ..
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"

# Update HTML
sed -i "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html
```

#### Step 10: Deploy website to S3
```bash
aws s3 sync website/ s3://rishabhmadne.com --delete
```

---

## 8. Verify Deployment

### Test endpoints:
```bash
# Get API URL
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"

# Test chatbot endpoint
curl -X POST "${API_URL}/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","sessionId":"test-123"}'

# Test visit endpoint
curl -X POST "${API_URL}/visit"
```

### Check website:
- Visit: https://rishabhmadne.com
- Test chatbot (bottom-right corner)
- Test contact form
- Check visit counter

---

## 9. Check Logs (if issues)

```bash
# Chatbot logs
aws logs tail /aws/lambda/chatbot-handler --follow

# Contact handler logs
aws logs tail /aws/lambda/contact-handler --follow

# Visit handler logs
aws logs tail /aws/lambda/visit-handler --follow
```

---

## Important Notes

### What Gets Created:
- ✅ New Lambda: `chatbot-handler`
- ✅ New DynamoDB table: `chatbot-conversations`
- ✅ New API Gateway endpoint: `/chatbot`
- ✅ Updated IAM permissions for Bedrock

### What Gets Reused:
- ✅ Existing S3 bucket: `rishabhmadne.com`
- ✅ Existing Lambda: `contact-handler`, `visit-handler`
- ✅ Existing DynamoDB: `contact-messages`, `visits`
- ✅ Existing API Gateway: `resume-api`

### Cost Impact:
- Additional ~$1-3/month for chatbot (Claude 3 Haiku)

---

## Troubleshooting

### Issue: Bedrock Access Denied
**Solution:**
1. Go to AWS Console → Bedrock → Model access
2. Request access to `Claude 3 Haiku`
3. Wait for approval (usually instant)
4. Re-run terraform apply

### Issue: Resource Already Exists
**Solution:**
```bash
cd terraform
# Import existing resource
terraform import aws_lambda_function.chatbot_handler chatbot-handler
# Then apply again
terraform apply -var="use_existing_resources=true"
```

### Issue: Lambda Deployment Failed
**Solution:**
```bash
# Destroy only chatbot resources
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations

# Re-apply
terraform apply -var="use_existing_resources=true"
```

### Issue: Website Not Updated
**Solution:**
```bash
# Clear CloudFront cache (if using CloudFront)
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"

# Or force S3 sync
aws s3 sync website/ s3://rishabhmadne.com --delete --cache-control "max-age=0"
```

### Issue: API Gateway Not Working
**Solution:**
```bash
# Redeploy API Gateway
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
```

---

## Cleanup (If needed)

### Remove only chatbot:
```bash
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations
```

### Remove everything:
```bash
cd terraform
terraform destroy
```

---

## Quick Reference Commands

```bash
# Check Terraform state
terraform state list

# Show specific resource
terraform state show aws_lambda_function.chatbot_handler

# Refresh state
terraform refresh

# View outputs
terraform output

# Format terraform files
terraform fmt

# Validate configuration
terraform validate
```

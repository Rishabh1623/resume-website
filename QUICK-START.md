# 🚀 Quick Start - Deploy in 5 Minutes

## From Your EC2 Instance

### Step 1: Clone & Setup (One-time)
```bash
# Clone repo
cd ~
git clone https://github.com/Rishabh1623/resume-website.git
cd resume-website

# Create config
cat > terraform/terraform.tfvars << 'EOF'
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
EOF
```

### Step 2: Package Lambda Functions
```bash
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..
```

### Step 3: Deploy with Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```
Type `yes` when prompted.

### Step 4: Update Website
```bash
cd ..
API_ID=$(cd terraform && terraform output -raw api_gateway_id)
sed -i "s|YOUR_API_GATEWAY_URL|https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod|g" website/index.html
aws s3 sync website/ s3://rishabhmadne.com --delete
```

### Step 5: Test
```bash
# Visit your website
curl https://rishabhmadne.com

# Test chatbot
curl -X POST "https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","sessionId":"test"}'
```

## Done! 🎉

Your website is now live with an AI-powered chatbot at https://rishabhmadne.com

---

## Update Later

If you make changes and want to redeploy:

```bash
cd ~/resume-website
git pull origin main

# Repackage Lambda if code changed
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

## Common Commands

```bash
# View Terraform outputs
cd terraform && terraform output

# Check logs
aws logs tail /aws/lambda/chatbot-handler --follow

# Destroy only chatbot
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations
```

---

## Need Help?

- Check `SIMPLE-DEPLOY.md` for detailed steps
- Check `OPTIMIZATION-SUMMARY.md` for what was optimized
- Check `DEPLOYMENT-STEPS.md` for troubleshooting

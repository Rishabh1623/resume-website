# Deployment Steps from EC2

## 1. Push Changes to GitHub

From your local Windows machine:
```bash
git push origin main
```

## 2. Connect to Ubuntu EC2 Instance

```bash
ssh -i "your-key.pem" ubuntu@your-ec2-ip
```

## 3. Install Prerequisites (if needed)

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
```

## 4. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Region: us-east-1
# Output format: json
```

## 5. Clone Repository

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/resume-website.git
cd resume-website
```

## 6. Create terraform.tfvars

```bash
cat > terraform/terraform.tfvars << 'EOF'
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
EOF
```

## 7. Deploy

```bash
chmod +x deploy-safe.sh
./deploy-safe.sh
```

## 8. Verify Deployment

After deployment completes:
- Visit: https://rishabhmadne.com
- Test the chatbot in the bottom-right corner
- Check contact form still works
- Verify visit counter updates

## Important Notes

- ✅ The deployment will NOT recreate your existing resources
- ✅ It will only ADD the new chatbot functionality
- ✅ Your existing website will continue working during deployment
- ✅ Expected additional cost: ~$1-3/month for chatbot

## Troubleshooting

### If Bedrock Access Denied:
1. Go to AWS Console → Bedrock → Model access
2. Request access to Claude 3 Haiku
3. Wait for approval (usually instant)
4. Re-run deployment

### If Lambda Deployment Fails:
```bash
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform apply -var="use_existing_resources=true"
```

### Check Logs:
```bash
aws logs tail /aws/lambda/chatbot-handler --follow
```

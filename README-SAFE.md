# Resume Website - Safe Deployment for Existing Resources

## 🚨 **For Existing AWS Resources**

If you already created resources in AWS Console, use this safe deployment approach to avoid conflicts.

## 🛠️ **Deployment Options**

### Option 1: Safe Deployment (Recommended)
**Use this if you have existing AWS resources**

```bash
# 1. Configure
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Safe deploy (automatically detects existing resources)
./deploy-safe.sh
```

### Option 2: Import Existing Resources
**Use this for full Terraform management**

```bash
# 1. Import existing resources
./import-existing.sh

# 2. Deploy normally
./deploy.sh
```

### Option 3: Fresh Deployment
**Use this for completely new setup**

```bash
# Set use_existing_resources = false in terraform.tfvars
./deploy.sh
```

## 🎯 **What Each Option Does**

### Safe Deployment
- ✅ **Detects existing resources automatically**
- ✅ **Only adds new chatbot functionality**
- ✅ **No conflicts with existing infrastructure**
- ✅ **Minimal changes to your current setup**

### Import Resources
- ✅ **Brings existing resources under Terraform management**
- ✅ **Full infrastructure as code**
- ⚠️ **Requires careful planning**

### Fresh Deployment
- ✅ **Creates everything new**
- ❌ **Will conflict with existing resources**

## 📋 **Safe Deployment Details**

The safe deployment will:

1. **Check for existing resources**:
   - S3 bucket
   - Lambda functions
   - API Gateway
   - DynamoDB tables

2. **Add only new components**:
   - Bedrock chatbot Lambda function
   - Chatbot DynamoDB table
   - Chatbot API Gateway endpoint
   - Updated IAM permissions

3. **Preserve existing setup**:
   - No changes to existing Lambda functions
   - No changes to existing DynamoDB tables
   - No changes to existing S3 configuration

## 🔧 **Configuration**

### terraform.tfvars
```hcl
aws_region = "us-east-1"
domain_name = "yourdomain.com"  # Your existing S3 bucket name
contact_email = "your-email@example.com"
use_existing_resources = true   # Set to true for existing resources
```

## 🚀 **Expected Results**

After safe deployment:
- ✅ Your existing website continues working
- ✅ Contact form continues working  
- ✅ Visit counter continues working
- ✅ **NEW**: AI chatbot functionality added
- ✅ **NEW**: Bedrock integration working

## 💰 **Cost Impact**

Additional costs for chatbot:
- **Claude 3 Haiku**: ~$1-3/month
- **Lambda**: ~$0.50/month
- **DynamoDB**: ~$0.50/month
- **Total additional**: ~$2-4/month

## 🔍 **Troubleshooting**

### Resource Conflicts
```bash
# If you get resource conflicts, try:
terraform state list
terraform state rm aws_resource.name  # Remove conflicting resource
```

### Permission Issues
```bash
# Ensure your AWS credentials have permissions for:
# - Bedrock model access
# - Lambda create/update
# - API Gateway modify
# - DynamoDB create
```

### Rollback
```bash
# To remove only the chatbot components:
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform destroy -target=aws_dynamodb_table.conversations
```

## 📞 **Support**

If you encounter issues:
1. Check AWS CloudWatch logs
2. Verify Bedrock model access
3. Ensure proper IAM permissions
4. Review Terraform state conflicts

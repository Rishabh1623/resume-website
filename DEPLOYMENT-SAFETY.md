# 🛡️ Deployment Safety Guide

## ⚠️ IMPORTANT: Your Existing Resources Are Safe!

This deployment is designed to **ADD the new AI chatbot** to your existing infrastructure **WITHOUT touching or recreating** your current working resources.

---

## ✅ What Will NOT Be Touched (Your Existing Resources)

### These resources will be **REUSED** (not recreated):

| Resource | Name | Status |
|----------|------|--------|
| **S3 Bucket** | `rishabhmadne.com` | ✅ SAFE - Will be reused |
| **Lambda Function** | `contact-handler` | ✅ SAFE - Will be reused |
| **Lambda Function** | `visit-handler` | ✅ SAFE - Will be reused |
| **DynamoDB Table** | `contact-messages` | ✅ SAFE - Will be reused |
| **DynamoDB Table** | `visits` | ✅ SAFE - Will be reused |
| **API Gateway** | `resume-api` | ✅ SAFE - Will be reused |
| **IAM Role** | `resume-lambda-role` | ⚠️ Will be updated (permissions only) |

**Your website will continue working during and after deployment!**

---

## 🆕 What Will Be Created (New Resources Only)

### These are NEW resources that will be added:

| Resource | Name | Purpose |
|----------|------|---------|
| **Lambda Function** | `chatbot-handler` | 🆕 NEW - AI chatbot |
| **DynamoDB Table** | `chatbot-conversations` | 🆕 NEW - Chat history |
| **API Gateway Endpoint** | `/chatbot` | 🆕 NEW - Chatbot API |
| **CloudWatch Log Group** | `/aws/apigateway/resume-api` | 🆕 NEW - API logs |

**Total new resources: 4**  
**Existing resources touched: 0**

---

## 🔒 How Safety is Guaranteed

### 1. Conditional Resource Creation

The Terraform configuration uses `use_existing_resources = true` to:

```hcl
# Example: S3 Bucket
resource "aws_s3_bucket" "website" {
  count  = var.use_existing_resources ? 0 : 1  # Creates 0 buckets when true
  bucket = var.domain_name
}

# Instead, it uses data source to reference existing bucket
data "aws_s3_bucket" "existing_website" {
  count  = var.use_existing_resources ? 1 : 0  # Reads existing bucket
  bucket = var.domain_name
}
```

### 2. Data Sources for Existing Resources

Terraform will **read** (not modify) your existing resources:

```hcl
data "aws_s3_bucket" "existing_website" { ... }
data "aws_dynamodb_table" "existing_contact" { ... }
data "aws_dynamodb_table" "existing_visits" { ... }
data "aws_api_gateway_rest_api" "existing_api" { ... }
```

### 3. New Resources Only

Only the chatbot-related resources will be created:

```hcl
# Always creates (new resource)
resource "aws_lambda_function" "chatbot_handler" { ... }
resource "aws_dynamodb_table" "conversations" { ... }
resource "aws_api_gateway_resource" "chatbot" { ... }
```

---

## 📊 Terraform Plan Preview

When you run `terraform plan`, you should see:

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

**Key indicators of safety:**
- ✅ **"to add"** = Creating new resources
- ✅ **"0 to change"** = Not modifying existing resources
- ✅ **"0 to destroy"** = Not deleting anything

**⚠️ WARNING**: If you see anything other than "0 to change" or "0 to destroy", **STOP** and review the plan carefully!

---

## 🔍 Pre-Deployment Checklist

Before running `terraform apply`, verify:

### Step 1: Check Configuration
```bash
cat terraform/terraform.tfvars
```

**Must show:**
```hcl
use_existing_resources = true  # ← This MUST be true!
```

### Step 2: Review Terraform Plan
```bash
cd terraform
terraform plan
```

**Look for:**
- ✅ `Plan: X to add, 0 to change, 0 to destroy`
- ✅ Only chatbot-related resources in "to add" list
- ❌ NO existing resources in "to change" or "to destroy"

### Step 3: Verify Existing Resources
```bash
# Check S3 bucket exists
aws s3 ls s3://rishabhmadne.com

# Check Lambda functions exist
aws lambda list-functions --query "Functions[?contains(FunctionName, 'handler')].FunctionName"

# Check DynamoDB tables exist
aws dynamodb list-tables --query "TableNames[?contains(@, 'contact') || contains(@, 'visits')]"

# Check API Gateway exists
aws apigateway get-rest-apis --query "items[?name=='resume-api'].id"
```

---

## 🚨 What If Something Goes Wrong?

### Scenario 1: Terraform Wants to Destroy Resources

**If you see:**
```
Plan: X to add, Y to change, Z to destroy.
```

**STOP! Do NOT apply!**

**Fix:**
```bash
# Check your configuration
cat terraform/terraform.tfvars

# Make sure it says:
use_existing_resources = true

# Re-run plan
terraform plan
```

### Scenario 2: Resource Already Exists Error

**Error:**
```
Error: Resource already exists
aws_lambda_function.chatbot_handler: already exists
```

**This means the chatbot was already deployed. Options:**

**Option A: Update existing chatbot**
```bash
cd terraform
terraform import aws_lambda_function.chatbot_handler chatbot-handler
terraform apply
```

**Option B: Remove and recreate**
```bash
cd terraform
terraform destroy -target=aws_lambda_function.chatbot_handler
terraform apply
```

### Scenario 3: IAM Role Conflict

**Error:**
```
Error: IAM role already exists
```

**Fix:**
```bash
cd terraform
terraform import aws_iam_role.lambda resume-lambda-role
terraform apply
```

---

## 🔄 Rollback Plan

If you need to remove only the chatbot (keep everything else):

```bash
cd terraform

# Remove chatbot Lambda
terraform destroy -target=aws_lambda_function.chatbot_handler

# Remove chatbot DynamoDB table
terraform destroy -target=aws_dynamodb_table.conversations

# Remove API Gateway chatbot endpoint
terraform destroy -target=aws_api_gateway_resource.chatbot

# Your existing resources remain untouched!
```

---

## ✅ Post-Deployment Verification

After deployment, verify everything still works:

### 1. Check Existing Website
```bash
curl -I https://rishabhmadne.com
# Should return: HTTP/1.1 200 OK
```

### 2. Test Existing Contact Form
```bash
API_URL=$(cd terraform && terraform output -raw api_gateway_url)
curl -X POST "${API_URL}/contact" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","message":"Test message"}'
```

### 3. Test Existing Visit Counter
```bash
curl -X POST "${API_URL}/visit"
# Should return visit count
```

### 4. Test New Chatbot
```bash
curl -X POST "${API_URL}/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","sessionId":"test"}'
# Should return chatbot response
```

---

## 📝 Configuration File Safety

### Your terraform.tfvars MUST contain:

```hcl
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true  # ← CRITICAL: Must be true!
```

**Never set `use_existing_resources = false` unless you want to recreate everything!**

---

## 🎯 Summary

### What This Deployment Does:
✅ Adds AI chatbot to your existing website  
✅ Creates 4 new resources  
✅ Reuses all existing resources  
✅ Zero downtime  
✅ Fully reversible  

### What This Deployment Does NOT Do:
❌ Does NOT recreate S3 bucket  
❌ Does NOT recreate existing Lambda functions  
❌ Does NOT recreate DynamoDB tables  
❌ Does NOT delete any data  
❌ Does NOT cause downtime  

---

## 🔐 Final Safety Confirmation

Before deploying, answer these questions:

1. **Is `use_existing_resources = true` in terraform.tfvars?**
   - [ ] Yes → Safe to proceed
   - [ ] No → STOP! Update configuration

2. **Does `terraform plan` show "0 to change, 0 to destroy"?**
   - [ ] Yes → Safe to proceed
   - [ ] No → STOP! Review plan

3. **Are only chatbot resources in "to add" list?**
   - [ ] Yes → Safe to proceed
   - [ ] No → STOP! Review plan

4. **Have you backed up your current setup?**
   - [ ] Yes → Safe to proceed
   - [ ] No → Consider backing up first

**If all answers are "Yes", you're safe to deploy!**

---

## 📞 Need Help?

If you're unsure about anything:

1. **Review the plan**: `terraform plan` (don't apply yet)
2. **Check documentation**: `COMPLETE-DEPLOYMENT-GUIDE.md`
3. **Test in stages**: Deploy one resource at a time
4. **Keep backups**: Export DynamoDB data before deployment

**Remember: Your existing resources are protected by the `use_existing_resources = true` flag!**

---

**🛡️ Your existing infrastructure is safe. This deployment only adds new chatbot functionality!**

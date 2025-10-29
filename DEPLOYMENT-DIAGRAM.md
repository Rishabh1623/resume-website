# 📊 Deployment Architecture Diagram

## Current State vs After Deployment

### BEFORE Deployment (Your Existing Setup)

```
┌─────────────────────────────────────────────────────────┐
│                    EXISTING RESOURCES                    │
│                  (Already Running - SAFE)                │
└─────────────────────────────────────────────────────────┘

┌──────────────┐
│   Website    │ ← S3: rishabhmadne.com
│   (Static)   │   ✅ WILL NOT BE TOUCHED
└──────┬───────┘
       │
       ↓ HTTPS
┌──────────────┐
│ API Gateway  │ ← resume-api
│              │   ✅ WILL BE REUSED (not recreated)
│ Endpoints:   │
│  /contact    │   ✅ EXISTING - SAFE
│  /visit      │   ✅ EXISTING - SAFE
└──────┬───────┘
       │
       ↓ Invoke
┌──────────────┐
│   Lambda     │
│              │
│ Functions:   │
│ • contact    │   ✅ EXISTING - SAFE
│ • visit      │   ✅ EXISTING - SAFE
└──────┬───────┘
       │
       ↓
┌──────────────┐
│  DynamoDB    │
│              │
│ Tables:      │
│ • contact-   │   ✅ EXISTING - SAFE
│   messages   │
│ • visits     │   ✅ EXISTING - SAFE
└──────────────┘
```

---

### AFTER Deployment (With New Chatbot)

```
┌─────────────────────────────────────────────────────────┐
│              EXISTING + NEW RESOURCES                    │
└─────────────────────────────────────────────────────────┘

┌──────────────┐
│   Website    │ ← S3: rishabhmadne.com
│   (Static)   │   ✅ UNCHANGED
└──────┬───────┘
       │
       ↓ HTTPS
┌──────────────┐
│ API Gateway  │ ← resume-api
│              │   ✅ REUSED (same API)
│ Endpoints:   │
│  /contact    │   ✅ EXISTING - Still works
│  /visit      │   ✅ EXISTING - Still works
│  /chatbot    │   🆕 NEW - Added endpoint
└──────┬───────┘
       │
       ↓ Invoke
┌──────────────┐
│   Lambda     │
│              │
│ Functions:   │
│ • contact    │   ✅ EXISTING - Unchanged
│ • visit      │   ✅ EXISTING - Unchanged
│ • chatbot    │   🆕 NEW - AI assistant
└──────┬───────┘
       │
       ↓
┌──────────────┐     ┌──────────────┐
│  DynamoDB    │     │   Bedrock    │
│              │     │   (Claude)   │
│ Tables:      │     │              │
│ • contact-   │     │ AI Model:    │
│   messages   │ ✅  │ • Claude 3   │ 🆕
│ • visits     │ ✅  │   Haiku      │
│ • chatbot-   │ 🆕  └──────────────┘
│   conversations│
└──────────────┘
```

---

## Resource Comparison Table

| Resource Type | Name | Before | After | Action |
|--------------|------|--------|-------|--------|
| **S3 Bucket** | rishabhmadne.com | ✅ Exists | ✅ Exists | ✅ REUSED |
| **API Gateway** | resume-api | ✅ Exists | ✅ Exists | ✅ REUSED |
| **Lambda** | contact-handler | ✅ Exists | ✅ Exists | ✅ REUSED |
| **Lambda** | visit-handler | ✅ Exists | ✅ Exists | ✅ REUSED |
| **Lambda** | chatbot-handler | ❌ None | ✅ Exists | 🆕 CREATED |
| **DynamoDB** | contact-messages | ✅ Exists | ✅ Exists | ✅ REUSED |
| **DynamoDB** | visits | ✅ Exists | ✅ Exists | ✅ REUSED |
| **DynamoDB** | chatbot-conversations | ❌ None | ✅ Exists | 🆕 CREATED |
| **API Endpoint** | /contact | ✅ Exists | ✅ Exists | ✅ REUSED |
| **API Endpoint** | /visit | ✅ Exists | ✅ Exists | ✅ REUSED |
| **API Endpoint** | /chatbot | ❌ None | ✅ Exists | 🆕 CREATED |

**Legend:**
- ✅ REUSED = Existing resource, not touched
- 🆕 CREATED = New resource, added
- ❌ None = Doesn't exist yet

---

## Deployment Flow

```
┌─────────────────────────────────────────────────────────┐
│                  DEPLOYMENT PROCESS                      │
└─────────────────────────────────────────────────────────┘

Step 1: Terraform Reads Existing Resources
┌──────────────────────────────────────┐
│  use_existing_resources = true       │
│                                      │
│  Terraform uses DATA SOURCES to:    │
│  • Read S3 bucket                   │
│  • Read API Gateway                 │
│  • Read DynamoDB tables             │
│  • Read Lambda functions            │
│                                      │
│  ✅ NO CHANGES to existing resources│
└──────────────────────────────────────┘
                 ↓
Step 2: Create New Resources Only
┌──────────────────────────────────────┐
│  Terraform creates:                  │
│  • chatbot-handler Lambda           │
│  • chatbot-conversations DynamoDB   │
│  • /chatbot API endpoint            │
│  • CloudWatch log group             │
│                                      │
│  🆕 4 NEW resources added            │
└──────────────────────────────────────┘
                 ↓
Step 3: Update IAM Permissions
┌──────────────────────────────────────┐
│  Update resume-lambda-role to add:  │
│  • Bedrock access                   │
│  • New DynamoDB table access        │
│                                      │
│  ⚠️ Only permissions updated         │
│  ✅ Existing permissions kept        │
└──────────────────────────────────────┘
                 ↓
Step 4: Deploy API Gateway
┌──────────────────────────────────────┐
│  Add /chatbot endpoint to           │
│  existing resume-api                │
│                                      │
│  ✅ /contact still works             │
│  ✅ /visit still works               │
│  🆕 /chatbot now available           │
└──────────────────────────────────────┘
                 ↓
Step 5: Verification
┌──────────────────────────────────────┐
│  Test all endpoints:                │
│  ✅ Website loads                    │
│  ✅ Contact form works               │
│  ✅ Visit counter works              │
│  🆕 Chatbot responds                 │
│                                      │
│  ✅ ZERO DOWNTIME                    │
└──────────────────────────────────────┘
```

---

## Safety Mechanisms

### 1. Conditional Resource Creation

```hcl
# Existing resources (count = 0 when use_existing_resources = true)
resource "aws_s3_bucket" "website" {
  count = var.use_existing_resources ? 0 : 1  # Creates 0 buckets
  ...
}

# New resources (always created)
resource "aws_lambda_function" "chatbot_handler" {
  # No count - always creates
  ...
}
```

### 2. Data Sources for Reading

```hcl
# Reads existing S3 bucket (doesn't modify)
data "aws_s3_bucket" "existing_website" {
  count  = var.use_existing_resources ? 1 : 0
  bucket = var.domain_name
}
```

### 3. Local Variables for References

```hcl
locals {
  # Uses existing API if available, otherwise new one
  api_id = var.use_existing_resources ? 
    data.aws_api_gateway_rest_api.existing_api[0].id : 
    aws_api_gateway_rest_api.main[0].id
}
```

---

## What Happens During Deployment

### Timeline

```
T+0s   : terraform plan starts
T+5s   : Reads existing resources (data sources)
T+10s  : Plans to create 8 new resources
T+15s  : Shows plan (0 to change, 0 to destroy)
         ⚠️ REVIEW PLAN HERE!
T+20s  : terraform apply starts (after confirmation)
T+25s  : Creates chatbot Lambda function
T+35s  : Creates chatbot DynamoDB table
T+40s  : Creates /chatbot API endpoint
T+45s  : Updates IAM role permissions
T+50s  : Deploys API Gateway
T+55s  : Creates CloudWatch log group
T+60s  : Deployment complete!

Total time: ~60 seconds
Downtime: 0 seconds
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing resources deleted | ❌ None | 🔴 High | `use_existing_resources = true` |
| Existing resources modified | ❌ None | 🟡 Medium | Data sources (read-only) |
| IAM permissions conflict | 🟡 Low | 🟡 Medium | Additive permissions only |
| API Gateway downtime | ❌ None | 🟡 Medium | Zero-downtime deployment |
| DynamoDB data loss | ❌ None | 🔴 High | New table, no existing data touched |
| Lambda function conflict | 🟡 Low | 🟢 Low | Different function names |

**Overall Risk: 🟢 LOW**

---

## Rollback Strategy

If something goes wrong, rollback is simple:

```bash
# Remove only new resources
cd terraform

# Remove chatbot Lambda
terraform destroy -target=aws_lambda_function.chatbot_handler

# Remove chatbot DynamoDB
terraform destroy -target=aws_dynamodb_table.conversations

# Remove chatbot API endpoint
terraform destroy -target=aws_api_gateway_resource.chatbot

# Your existing resources remain untouched!
```

**Rollback time: ~30 seconds**

---

## Summary

### What Gets Added:
- 🆕 1 Lambda function (chatbot-handler)
- 🆕 1 DynamoDB table (chatbot-conversations)
- 🆕 1 API endpoint (/chatbot)
- 🆕 1 CloudWatch log group

### What Gets Reused:
- ✅ S3 bucket (rishabhmadne.com)
- ✅ API Gateway (resume-api)
- ✅ 2 Lambda functions (contact, visit)
- ✅ 2 DynamoDB tables (contact-messages, visits)

### What Gets Modified:
- ⚠️ IAM role (permissions only - additive, not destructive)

### What Gets Deleted:
- ❌ NOTHING!

---

**🛡️ Your existing infrastructure is completely safe!**

This deployment only adds new chatbot functionality without touching your working resources.

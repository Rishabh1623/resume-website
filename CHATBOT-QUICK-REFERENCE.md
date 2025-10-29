# 🤖 Advanced Chatbot - Quick Reference

## Deploy Advanced Version

```bash
# 1. Replace with advanced handler
cp lambda/chatbot-handler-advanced.mjs lambda/chatbot-handler.mjs

# 2. Package
cd lambda
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..

# 3. Deploy
cd terraform
terraform apply
cd ..

# 4. Update website (add enhanced JS)
# Add this line before </body> in website/index.html:
# <script src="chatbot-enhanced.js"></script>

# 5. Upload to S3
aws s3 sync website/ s3://rishabhmadne.com --delete
```

---

## Key Features

### 🎯 Intent Classification
Automatically detects 6 types of visitors:
- **HIRING** - Recruiters, hiring managers
- **TECHNICAL** - Engineers asking technical questions
- **EXPERIENCE** - Questions about work history
- **SKILLS** - Technology stack inquiries
- **CONTACT** - Meeting scheduling requests
- **GENERAL** - General inquiries

### 🧠 Context Awareness
- Remembers last 5 messages
- Knows which page section user is viewing
- Adapts tone based on intent
- Provides relevant follow-ups

### ⚡ Dynamic Actions
- `schedule_meeting` - Opens email
- `download_resume` - Triggers download
- `show_projects` - Scrolls to projects
- `show_experience` - Scrolls to experience
- `show_skills` - Scrolls to skills

### 🎨 Enhanced UI
- Typing effect (character-by-character)
- Suggestion chips (quick replies)
- Typing indicator (animated dots)
- Smooth animations
- Auto-scroll

---

## Test Commands

### Test Intent Detection
```bash
API_URL="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

# Hiring intent
curl -X POST "$API_URL/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Are you looking for a job?","sessionId":"test1"}'

# Technical intent
curl -X POST "$API_URL/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"How did you implement the EKS migration?","sessionId":"test2"}'

# Experience intent
curl -X POST "$API_URL/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Tell me about your projects","sessionId":"test3"}'
```

### Test Context Awareness
```bash
# First message
curl -X POST "$API_URL/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"What AWS services do you use?","sessionId":"context-test"}'

# Follow-up (uses history)
curl -X POST "$API_URL/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Tell me more about Lambda","sessionId":"context-test"}'
```

---

## Configuration

### Adjust Response Length
In `lambda/chatbot-handler-advanced.mjs`:
```javascript
const payload = {
  max_tokens: 500,  // Increase for longer responses
  temperature: 0.8, // 0.0-1.0 (higher = more creative)
  top_p: 0.9
};
```

### Modify Intent Keywords
```javascript
const INTENTS = {
  HIRING: ['hire', 'job', 'position', 'role', 'opportunity'],
  TECHNICAL: ['how', 'technical', 'architecture', 'implement'],
  // Add more keywords as needed
};
```

### Change Conversation History Length
```javascript
// In storeConversation function
const recentHistory = history.slice(-5);  // Change -5 to -10 for more history
```

### Adjust TTL (Session Duration)
```javascript
ttl: Math.floor(Date.now() / 1000) + 7200  // 2 hours (change 7200 to desired seconds)
```

---

## Monitoring

### View Logs
```bash
# Real-time logs
aws logs tail /aws/lambda/chatbot-handler --follow

# Last 100 lines
aws logs tail /aws/lambda/chatbot-handler --since 1h

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/chatbot-handler \
  --filter-pattern "ERROR"
```

### Check Metrics
```bash
# Invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=chatbot-handler \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum

# Error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=chatbot-handler \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

---

## Troubleshooting

### Issue: Chatbot not responding
```bash
# Check Lambda logs
aws logs tail /aws/lambda/chatbot-handler --follow

# Check API Gateway
aws apigateway get-rest-apis --query "items[?name=='resume-api']"

# Test endpoint directly
curl -X POST "$API_URL/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"test","sessionId":"debug"}'
```

### Issue: Bedrock access denied
```bash
# Check Bedrock model access
aws bedrock list-foundation-models --region us-east-1

# Request access in AWS Console:
# Bedrock → Model access → Request access to Claude 3 Haiku
```

### Issue: DynamoDB errors
```bash
# Check table exists
aws dynamodb describe-table --table-name chatbot-conversations

# Check IAM permissions
aws iam get-role-policy \
  --role-name resume-lambda-role \
  --policy-name resume-lambda-custom-policy
```

### Issue: High costs
```bash
# Check Bedrock usage
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://bedrock-filter.json

# Reduce costs:
# 1. Lower max_tokens (500 → 300)
# 2. Reduce history (5 → 3)
# 3. Shorter TTL (2h → 1h)
```

---

## Performance Tuning

### Reduce Cold Starts
```javascript
// Keep Lambda warm with scheduled pings
aws events put-rule \
  --name chatbot-warmer \
  --schedule-expression "rate(5 minutes)"
```

### Optimize Response Time
```javascript
// In Lambda handler:
// 1. Move SDK clients outside handler ✅ (already done)
// 2. Reduce max_tokens
// 3. Use provisioned concurrency (costs more)
```

### Reduce Costs
```javascript
// 1. Lower max_tokens
max_tokens: 300  // vs 500

// 2. Shorter history
history.slice(-3)  // vs -5

// 3. Shorter TTL
ttl: 3600  // 1 hour vs 2 hours
```

---

## Customization Examples

### Add New Intent
```javascript
// 1. Add to INTENTS
const INTENTS = {
  // ... existing intents
  PRICING: ['price', 'cost', 'rate', 'budget', 'fee']
};

// 2. Add to default suggestions
function generateDefaultSuggestions(intent) {
  const suggestions = {
    // ... existing suggestions
    PRICING: [
      "What's your hourly rate?",
      "Do you work on fixed-price projects?",
      "What's included in your services?"
    ]
  };
  return suggestions[intent] || suggestions.GENERAL;
}
```

### Add New Action
```javascript
// 1. In Lambda response
{
  "message": "Here's my LinkedIn profile",
  "actions": [{"type": "open_linkedin", "data": {}}]
}

// 2. In frontend (chatbot-enhanced.js)
handleActions(actions) {
  actions.forEach(action => {
    switch (action.type) {
      // ... existing actions
      case 'open_linkedin':
        window.open('https://linkedin.com/in/yourprofile', '_blank');
        break;
    }
  });
}
```

### Customize Personality
```javascript
// In SYSTEM_PROMPT
const SYSTEM_PROMPT = `You are Rishabh's AI Career Assistant.

PERSONALITY:
- Friendly and approachable (vs Professional and formal)
- Use emojis occasionally 😊
- Keep responses conversational
- Show enthusiasm about projects

// ... rest of prompt
`;
```

---

## Cost Breakdown

### Per Conversation
- Bedrock: $0.0005 (500 tokens)
- Lambda: $0.0001 (256MB, 2s)
- DynamoDB: $0.00002 (read/write)
- API Gateway: $0.00035
- **Total: ~$0.001 per conversation**

### Monthly (3000 conversations)
- Bedrock: $1.50
- Lambda: $0.30
- DynamoDB: $0.06
- API Gateway: $1.05
- **Total: ~$3/month**

---

## Quick Links

- **Full Documentation**: `docs/ADVANCED-CHATBOT.md`
- **Showcase Guide**: `CHATBOT-SHOWCASE.md`
- **Deployment Guide**: `QUICK-START.md`
- **Lambda Code**: `lambda/chatbot-handler-advanced.mjs`
- **Frontend Code**: `website/chatbot-enhanced.js`

---

## Support

Questions? Check:
1. `docs/ADVANCED-CHATBOT.md` - Technical details
2. `CHATBOT-SHOWCASE.md` - Interview talking points
3. CloudWatch logs - Runtime issues
4. GitHub Issues - Bug reports

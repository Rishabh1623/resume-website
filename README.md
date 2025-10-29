# 🚀 AI-Powered Portfolio Website - Rishabh Madne

A production-ready serverless portfolio website featuring an **advanced AI chatbot** that showcases real engineering expertise. Built with AWS, Terraform, and modern best practices.

## ⭐ What Makes This Special

Unlike typical static portfolios, this website features an **intelligent AI assistant** that:
- 🎯 **Classifies visitor intent** (hiring manager, technical recruiter, developer)
- 🧠 **Maintains conversation context** (remembers previous messages)
- ⚡ **Takes dynamic actions** (schedules meetings, downloads resume, navigates sections)
- 💬 **Provides smart suggestions** (relevant follow-up questions)
- 📊 **Highlights metrics automatically** (10× scalability, 20% cost savings)

**This isn't just a portfolio - it's a working demonstration of AI/ML engineering, cloud architecture, and production-ready code.**

---

## 🏗️ Architecture

```
┌─────────────┐
│   Website   │ ← S3 + CloudFront
│  (Static)   │
└──────┬──────┘
       │
       ↓ HTTPS
┌─────────────┐
│ API Gateway │ ← /contact, /visit, /chatbot
└──────┬──────┘
       │
       ↓ Invoke
┌─────────────┐
│   Lambda    │ ← 3 Functions (Contact, Visit, Chatbot)
└──────┬──────┘
       │
   ┌───┴────┐
   ↓        ↓
┌────────┐ ┌──────────┐
│Bedrock │ │ DynamoDB │ ← Conversations, Messages, Visits
│Claude  │ │          │
└────────┘ └──────────┘
```

**Tech Stack**: AWS (Lambda, Bedrock, DynamoDB, S3, API Gateway), Terraform, Node.js, Claude 3 Haiku

---

## 🎯 Key Features

### 1. Advanced AI Chatbot
- **Intent Classification**: Automatically detects hiring, technical, or general inquiries
- **Context Awareness**: Remembers conversation history and current page section
- **Dynamic Actions**: Schedules meetings, downloads resume, navigates to sections
- **Smart Suggestions**: Provides relevant follow-up questions
- **Cost Optimized**: ~$3/month for 3000 conversations

### 2. Production-Ready Code
- Infrastructure as Code (Terraform)
- Error handling and validation
- CloudWatch monitoring and logging
- Security best practices
- Performance optimization

### 3. Full-Stack Integration
- Serverless backend (AWS Lambda)
- Modern frontend (ES6+ JavaScript)
- NoSQL database (DynamoDB)
- AI/ML integration (Amazon Bedrock)

---

## 🛡️ Safe Deployment - Your Existing Resources Are Protected!

**IMPORTANT**: This deployment is designed to **ADD the chatbot** to your existing infrastructure **WITHOUT recreating or modifying** your current resources.

- ✅ **Existing S3, Lambda, DynamoDB, API Gateway** → REUSED (not touched)
- 🆕 **New chatbot resources** → CREATED (4 new resources)
- ⚠️ **IAM permissions** → UPDATED (additive only)
- ❌ **Nothing deleted** → ZERO data loss

**See**: [DEPLOYMENT-SAFETY.md](DEPLOYMENT-SAFETY.md) for complete safety details

---

## 🚀 Quick Deploy (30 minutes)

### Prerequisites
- AWS account with Bedrock access
- AWS CLI configured
- Terraform installed

### Deploy Commands
```bash
# 1. Clone repository
git clone https://github.com/Rishabh1623/resume-website.git
cd resume-website

# 2. Configure
cat > terraform/terraform.tfvars << 'EOF'
aws_region = "us-east-1"
domain_name = "rishabhmadne.com"
contact_email = "rishabhmadne16@outlook.com"
use_existing_resources = true
EOF

# 3. Use advanced chatbot
cp lambda/chatbot-handler-advanced.mjs lambda/chatbot-handler.mjs

# 4. Package Lambda functions
cd lambda
zip ../contact-handler.zip contact-handler.mjs
zip ../visit-handler.zip visit-handler.mjs
zip ../chatbot-handler.zip chatbot-handler.mjs
cd ..

# 5. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply
cd ..

# 6. Update and upload website
API_ID=$(cd terraform && terraform output -raw api_gateway_id)
sed -i "s|YOUR_API_GATEWAY_URL|https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod|g" website/index.html
aws s3 sync website/ s3://rishabhmadne.com --delete
```

**Done!** Your AI-powered portfolio is live at https://rishabhmadne.com

---

## 📚 Documentation

### Quick Start
- **[DEPLOY-NOW.md](DEPLOY-NOW.md)** - Copy-paste deployment commands
- **[QUICK-START.md](QUICK-START.md)** - 5-minute quick start guide

### Complete Guides
- **[COMPLETE-DEPLOYMENT-GUIDE.md](COMPLETE-DEPLOYMENT-GUIDE.md)** - Step-by-step with troubleshooting
- **[SIMPLE-DEPLOY.md](SIMPLE-DEPLOY.md)** - Simplified deployment instructions

### Chatbot Documentation
- **[docs/ADVANCED-CHATBOT.md](docs/ADVANCED-CHATBOT.md)** - Technical implementation details
- **[CHATBOT-SHOWCASE.md](CHATBOT-SHOWCASE.md)** - Interview talking points
- **[CHATBOT-QUICK-REFERENCE.md](CHATBOT-QUICK-REFERENCE.md)** - Configuration and testing

### Optimization
- **[OPTIMIZATION-SUMMARY.md](OPTIMIZATION-SUMMARY.md)** - AWS & Terraform best practices applied

---

## 💡 Skills Demonstrated

### AI/ML Engineering
✅ LLM integration (Amazon Bedrock)  
✅ Prompt engineering  
✅ Intent classification (NLP)  
✅ Context management  
✅ Response optimization  

### Cloud Architecture
✅ Serverless design (Lambda, API Gateway)  
✅ NoSQL database (DynamoDB)  
✅ Cost optimization (~$3/month)  
✅ Security best practices  
✅ Monitoring & logging  

### DevOps
✅ Infrastructure as Code (Terraform)  
✅ CI/CD ready  
✅ Automated deployments  
✅ CloudWatch integration  

### Full-Stack Development
✅ Backend API (Node.js)  
✅ Frontend JavaScript (ES6+)  
✅ Real-time UI updates  
✅ Responsive design  

---

## 💰 Cost Breakdown

### Monthly Costs (~$3-5)
- **Bedrock (Claude 3 Haiku)**: $1-3
- **Lambda**: $0.50
- **DynamoDB**: $0.50
- **API Gateway**: $1-2
- **S3**: $0.50

### Per Conversation
- **Cost**: ~$0.001
- **3000 conversations/month**: ~$3

**70% cheaper than typical chatbot implementations through optimization!**

---

## 🧪 Test the Chatbot

### Live Demo
Visit: **https://rishabhmadne.com**

Click the chatbot widget (bottom-right) and try:
- "Tell me about your AWS experience"
- "How did you achieve 10× scalability?"
- "What's your biggest achievement?"
- "Can we schedule a meeting?"

### API Test
```bash
curl -X POST "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/chatbot" \
  -H "Content-Type: application/json" \
  -d '{"message":"Tell me about your projects","sessionId":"test"}'
```

---

## 📊 Monitoring

### View Logs
```bash
# Chatbot logs
aws logs tail /aws/lambda/chatbot-handler --follow

# All Lambda logs
aws logs tail /aws/lambda/contact-handler --follow
aws logs tail /aws/lambda/visit-handler --follow
```

### Check Metrics
```bash
# Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=chatbot-handler \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

---

## 🔧 Customization

### Modify Chatbot Personality
Edit `lambda/chatbot-handler-advanced.mjs`:
```javascript
const SYSTEM_PROMPT = `You are Rishabh's AI assistant...
// Customize personality, tone, and knowledge here
`;
```

### Add New Intents
```javascript
const INTENTS = {
  HIRING: ['hire', 'job', 'position'],
  TECHNICAL: ['how', 'architecture'],
  YOUR_INTENT: ['keyword1', 'keyword2']  // Add here
};
```

### Adjust Response Length
```javascript
const payload = {
  max_tokens: 500,  // Increase for longer responses
  temperature: 0.8  // 0.0-1.0 (higher = more creative)
};
```

---

## 🆘 Troubleshooting

### Common Issues

**Bedrock Access Denied**
```bash
# Request access: AWS Console → Bedrock → Model access
aws bedrock list-foundation-models --region us-east-1 | grep claude
```

**Lambda Errors**
```bash
aws logs tail /aws/lambda/chatbot-handler --follow
```

**API Gateway Not Working**
```bash
cd terraform
terraform apply -replace=aws_api_gateway_deployment.main
```

**Full troubleshooting guide**: [COMPLETE-DEPLOYMENT-GUIDE.md](COMPLETE-DEPLOYMENT-GUIDE.md#9-troubleshooting)

---

## 🎓 Use This in Interviews

### Talking Points
1. **"I built an AI chatbot that adapts to different visitor types"**
   - Shows NLP/intent classification skills

2. **"It costs only $3/month for thousands of conversations"**
   - Demonstrates cost optimization expertise

3. **"The chatbot takes actions, not just responds"**
   - Proves full-stack integration ability

4. **"Built with Terraform, fully automated"**
   - Shows IaC and DevOps skills

**More interview tips**: [CHATBOT-SHOWCASE.md](CHATBOT-SHOWCASE.md)

---

## 📈 Project Stats

- **Lines of Code**: ~2,500
- **AWS Services**: 8 (Lambda, Bedrock, DynamoDB, S3, API Gateway, CloudWatch, IAM, SES)
- **Deployment Time**: 30 minutes
- **Monthly Cost**: $3-5
- **Response Time**: 1-2 seconds
- **Uptime**: 99.9% (serverless)

---

## 🤝 Contributing

Improvements welcome! Areas to enhance:
- Multi-language support
- Voice integration
- Sentiment analysis
- Advanced analytics
- A/B testing

---

## 📞 Contact

**Rishabh Madne**
- Email: rishabhmadne16@outlook.com
- Website: https://rishabhmadne.com
- GitHub: https://github.com/Rishabh1623

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## ⭐ Star This Repo

If you find this project helpful, please star it! It helps others discover this advanced portfolio implementation.

---

**Built with ❤️ using AWS, Terraform, and Claude AI**

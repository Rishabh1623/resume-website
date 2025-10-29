# Resume Website with AWS Serverless Architecture

A modern, cost-optimized serverless resume website built with AWS services and automated CI/CD pipeline.

## 🏗️ Architecture
- **Frontend**: Static website hosted on S3
- **Backend**: Lambda functions with API Gateway
- **Database**: DynamoDB for contact messages and visit tracking
- **AI Chatbot**: Bedrock-powered assistant using Claude 3 Haiku
- **CI/CD**: GitHub Actions for automated deployment

## 🚀 Features
- Responsive resume website
- Contact form with email notifications
- Visit counter tracking
- AI-powered chatbot assistant
- Cost-optimized serverless architecture (~$5-7/month)
- Automated deployment pipeline

## 📋 Prerequisites
- AWS Account with Bedrock access
- GitHub Account
- Domain name (optional)

## 🛠️ Quick Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/resume-website.git
cd resume-website
```

### 2. Configure AWS Credentials
Add these secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 3. Update Configuration
Update `terraform/terraform.tfvars`:
```hcl
domain_name = "yourdomain.com"
contact_email = "your-email@example.com"
aws_region = "us-east-1"
```

### 4. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 5. Deploy Website
```bash
./deploy.sh
```

## 🤖 AI Chatbot
The website includes an intelligent chatbot powered by Amazon Bedrock (Claude 3 Haiku) that can:
- Answer questions about experience and skills
- Schedule meetings via email
- Download resume
- Navigate to different sections

## 💰 Cost Estimation (Monthly)
- **Bedrock (Claude 3 Haiku)**: ~$1-3
- **Lambda**: ~$0.50
- **DynamoDB**: ~$0.50
- **API Gateway**: ~$3.50
- **S3**: ~$1-2
- **Total**: ~$5-7/month

## 🔧 Local Development
```bash
# Test Lambda functions locally
cd lambda
npm test

# Preview website
cd website
python -m http.server 8000
```

## 📊 Monitoring
- CloudWatch logs for Lambda functions
- DynamoDB metrics in AWS Console
- API Gateway metrics and logs

## 🔄 CI/CD Pipeline
Automated deployment on push to main branch:
1. Update Lambda functions
2. Deploy website to S3
3. Test API endpoints
4. Notify on completion

## 🤝 Contributing
1. Fork the repository
2. Create feature branch
3. Make changes
4. Submit pull request

## 📚 Documentation
- [Deployment Guide](docs/DEPLOYMENT.md)
- [API Documentation](docs/API.md)
- [Chatbot Configuration](docs/CHATBOT.md)

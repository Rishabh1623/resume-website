# 🌐 Serverless Resume Website on AWS – Rishabh Ravi Madne

This repository hosts my personal resume as a **serverless, production-grade website** built on AWS infrastructure.  
It demonstrates real-world implementation of core AWS services with best practices in cost, performance, and security.

🔗 Live Demo (Coming Soon): https://resume.rishabhmadne.com

---

## 🚀 Why Host a Resume on AWS?

> "Show, don’t just tell" – this project turns my resume into a **living technical portfolio**.

- ✅ Demonstrates practical AWS experience
- ✅ Great conversation starter in interviews
- ✅ Highlights cost-optimization, IaC, and serverless patterns
- ✅ Easy to scale and update

---

## 🧱 Architecture Overview

This is a **fully serverless architecture** designed with performance and security in mind.

### 📦 Core Components

| AWS Service       | Role |
|------------------|------|
| **Amazon S3**     | Hosts static files (HTML/CSS) |
| **Amazon CloudFront** | Global CDN for fast content delivery |
| **Route 53**      | Custom domain & DNS management |
| **Certificate Manager** | HTTPS with free SSL |
| **Lambda + API Gateway** | Handles dynamic features (e.g. visitor counter, contact form) |
| **DynamoDB**      | Stores contact form data / visit analytics |

cloud_resume_site/
│
├── index.html # Main resume page
├── projects.html # Dedicated project portfolio
├── style.css # Stylesheet for both pages
├── README.md # You're reading this


---

## 🧠 Features

- ✅ Mobile-responsive HTML + CSS design
- ✅ AWS Bedrock, Lambda, DynamoDB–ready backend hooks
- ✅ Global content delivery with CloudFront
- ✅ CI/CD-ready (via GitHub Actions)
- ✅ Infrastructure-as-Code ready (Terraform/CloudFormation)

---

## 🛠️ How to Deploy (Manual Steps)

1. **Create an S3 bucket** and enable static website hosting.
2. **Upload files:** `index.html`, `projects.html`, `style.css`.
3. **Set up CloudFront** with:
   - Origin Access Control (OAC) to S3
   - HTTPS via AWS Certificate Manager
4. **Configure Route 53** to point `resume.yourdomain.com` to CloudFront.
5. (Optional) **Add Lambda + API Gateway** for dynamic features.
6. (Optional) **Add CI/CD pipeline** using GitHub Actions.

---

## 📝 Future Enhancements

- [ ] Contact form with API Gateway + Lambda + DynamoDB
- [ ] Visitor analytics tracker using CloudWatch or DynamoDB
- [ ] CI/CD pipeline to auto-deploy from GitHub
- [ ] Terraform IaC templates for full stack provisioning

---

## 📚 Featured Projects

| Project | Description |
|--------|-------------|
| [GenAI-Powered Medical Coding](https://www.linkedin.com/pulse/automating-medical-coding-genai-aws-real-world-healthtech-madne-laq1f/) | Used Bedrock, Lambda & DynamoDB to automate ICD-10 tagging |
| [Serverless Food Delivery Platform](https://www.linkedin.com/pulse/how-i-built-scalable-serverless-food-delivery-platform-rishabh-madne-04unf/) | Built with Lambda, API Gateway, DynamoDB, GitHub Actions |
| [SpendWise AWS Cost Dashboard](https://www.linkedin.com/pulse/spendwise-building-custom-aws-cost-optimization-dashboard-madne-szx6f/) | Custom AWS cost optimization insights with S3, Athena, Quicksight |
| [Scalable WordPress on AWS](https://www.linkedin.com/pulse/how-i-built-scalable-wordpress-blog-aws-without-single-rishabh-madne-7qtaf/) | Multi-AZ deployment using EC2, RDS, EFS, CloudFront |

---

## 🙋‍♂️ About Me

**Rishabh Ravi Madne**  
AWS Solutions Architect | Terraform | Kubernetes | Cloud-Native Systems  
📍 Jersey City, NJ  
📧 rishabhmadne16@outlook.com  
🔗 [LinkedIn](https://www.linkedin.com/in/rishabhmadne) | [GitHub](https://github.com/Rishabh1623)

---

---

## 🗂️ Project Structure


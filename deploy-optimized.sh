#!/bin/bash
# Optimized Deployment Script - AWS Best Practices

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  command -v terraform >/dev/null 2>&1 || { log_error "Terraform not found"; exit 1; }
  command -v aws >/dev/null 2>&1 || { log_error "AWS CLI not found"; exit 1; }
  command -v zip >/dev/null 2>&1 || { log_error "zip not found"; exit 1; }
  
  aws sts get-caller-identity >/dev/null 2>&1 || { log_error "AWS credentials not configured"; exit 1; }
  
  log_info "All prerequisites met"
}

# Package Lambda functions
package_lambdas() {
  log_info "Packaging Lambda functions..."
  
  cd lambda
  
  # Use optimized versions if they exist
  if [ -f "chatbot-handler-optimized.mjs" ]; then
    zip -q ../chatbot-handler.zip chatbot-handler-optimized.mjs
    mv chatbot-handler-optimized.mjs chatbot-handler.mjs
  else
    zip -q ../chatbot-handler.zip chatbot-handler.mjs
  fi
  
  if [ -f "contact-handler-optimized.mjs" ]; then
    zip -q ../contact-handler.zip contact-handler-optimized.mjs
    mv contact-handler-optimized.mjs contact-handler.mjs
  else
    zip -q ../contact-handler.zip contact-handler.mjs
  fi
  
  if [ -f "visit-handler-optimized.mjs" ]; then
    zip -q ../visit-handler.zip visit-handler-optimized.mjs
    mv visit-handler-optimized.mjs visit-handler.mjs
  else
    zip -q ../visit-handler.zip visit-handler.mjs
  fi
  
  cd ..
  log_info "Lambda functions packaged"
}

# Deploy infrastructure
deploy_infrastructure() {
  log_info "Deploying infrastructure..."
  
  cd terraform
  
  # Check if terraform.tfvars exists
  if [ ! -f "terraform.tfvars" ]; then
    log_error "terraform.tfvars not found"
    exit 1
  fi
  
  # Use optimized configuration if it exists
  if [ -f "main-optimized.tf" ]; then
    log_info "Using optimized Terraform configuration"
    cp main-optimized.tf main.tf
    cp outputs-optimized.tf outputs.tf
  fi
  
  # Initialize
  terraform init -upgrade
  
  # Validate
  terraform validate || { log_error "Terraform validation failed"; exit 1; }
  
  # Format
  terraform fmt
  
  # Plan
  log_info "Creating deployment plan..."
  terraform plan -out=tfplan
  
  # Apply
  log_info "Applying changes..."
  terraform apply tfplan
  
  # Clean up plan file
  rm -f tfplan
  
  cd ..
  log_info "Infrastructure deployed"
}

# Update website
update_website() {
  log_info "Updating website..."
  
  cd terraform
  API_ID=$(terraform output -raw api_gateway_id 2>/dev/null || echo "")
  cd ..
  
  if [ -z "$API_ID" ]; then
    log_warn "Could not get API Gateway ID from Terraform"
    API_ID=$(aws apigateway get-rest-apis --query "items[?name=='resume-api'].id" --output text)
  fi
  
  if [ -z "$API_ID" ] || [ "$API_ID" == "None" ]; then
    log_error "Could not determine API Gateway ID"
    exit 1
  fi
  
  REGION=$(aws configure get region || echo "us-east-1")
  API_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
  
  log_info "API URL: $API_URL"
  
  # Update HTML
  sed -i.bak "s|YOUR_API_GATEWAY_URL|${API_URL}|g" website/index.html
  
  # Get domain name
  DOMAIN=$(grep 'domain_name' terraform/terraform.tfvars | cut -d'"' -f2)
  
  # Upload to S3
  aws s3 sync website/ "s3://${DOMAIN}" --delete --cache-control "max-age=300"
  
  # Restore original
  mv website/index.html.bak website/index.html
  
  log_info "Website updated"
}

# Test endpoints
test_endpoints() {
  log_info "Testing endpoints..."
  
  cd terraform
  API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
  cd ..
  
  if [ -z "$API_URL" ]; then
    log_warn "Skipping endpoint tests"
    return
  fi
  
  # Test chatbot
  if curl -sf "${API_URL}/chatbot" -X POST \
    -H "Content-Type: application/json" \
    -d '{"message":"test","sessionId":"deploy-test"}' >/dev/null 2>&1; then
    log_info "Chatbot endpoint working"
  else
    log_warn "Chatbot endpoint test failed (may need time to propagate)"
  fi
}

# Main execution
main() {
  echo "========================================="
  echo "  Optimized Deployment Script"
  echo "========================================="
  echo ""
  
  check_prerequisites
  package_lambdas
  deploy_infrastructure
  update_website
  test_endpoints
  
  echo ""
  echo "========================================="
  log_info "Deployment completed successfully!"
  echo "========================================="
  echo ""
  
  cd terraform
  terraform output
  cd ..
}

# Run main function
main "$@"

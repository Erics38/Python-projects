#!/bin/bash

# Professional Terraform Backend Setup Script
# Creates S3 bucket and DynamoDB table for remote state management

set -e

echo "🏗️  Setting up Terraform backend for professional state management..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed or not in PATH"
    exit 1
fi

# Check if Terraform is available
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed or not in PATH"
    exit 1
fi

# Check AWS credentials
echo "🔍 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or expired"
    echo "Please run: aws configure"
    exit 1
fi

CALLER_IDENTITY=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo $CALLER_IDENTITY | jq -r '.Account')
USER_ARN=$(echo $CALLER_IDENTITY | jq -r '.Arn')

print_status "Connected to AWS Account: $ACCOUNT_ID"
print_status "User: $USER_ARN"

# Navigate to backend directory
cd backend

# Initialize Terraform
echo ""
echo "🚀 Initializing Terraform backend setup..."
terraform init

# Plan the backend resources
echo ""
echo "📋 Planning backend resources..."
terraform plan

# Ask for confirmation
echo ""
print_warning "This will create:"
print_warning "- S3 bucket for Terraform state storage"
print_warning "- DynamoDB table for state locking"
print_warning "- IAM policy for backend access"
echo ""
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Setup cancelled by user"
    exit 1
fi

# Apply the backend configuration
echo ""
echo "🏗️  Creating backend resources..."
terraform apply -auto-approve

# Get outputs
BUCKET_NAME=$(terraform output -raw terraform_state_bucket)
TABLE_NAME=$(terraform output -raw dynamodb_table)
BACKEND_CONFIG=$(terraform output -raw backend_config_text)

print_status "Backend resources created successfully!"
echo ""
print_status "S3 Bucket: $BUCKET_NAME"
print_status "DynamoDB Table: $TABLE_NAME"

# Save backend configuration to file
cat > ../backend-config.txt << EOF
$BACKEND_CONFIG
EOF

print_status "Backend configuration saved to: backend-config.txt"

echo ""
print_warning "🔧 Next Steps:"
echo "1. Copy the backend configuration from backend-config.txt"
echo "2. Uncomment the backend block in main.tf"
echo "3. Replace the placeholder values with your actual bucket name"
echo "4. Run: terraform init -migrate-state"
echo ""
print_status "Your Terraform state will then be stored securely in S3 with DynamoDB locking!"

# Return to main directory
cd ..

print_status "Backend setup complete! 🎉"
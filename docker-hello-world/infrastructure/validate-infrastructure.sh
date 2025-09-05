#!/bin/bash

# Infrastructure Validation Script
# Comprehensive testing of Terraform configuration before deployment

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Initialize validation results
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

echo "🔍 Starting Comprehensive Infrastructure Validation..."
echo "=================================================="

# Test 1: Check Terraform Configuration Structure
print_header "1. Validating Terraform Configuration Structure"

if [ -f "main.tf" ]; then
    print_success "Main configuration file exists"
else
    print_error "main.tf not found"
    ((VALIDATION_ERRORS++))
fi

if [ -f "variables.tf" ]; then
    print_success "Variables file exists"
else
    print_error "variables.tf not found"
    ((VALIDATION_ERRORS++))
fi

if [ -f "outputs.tf" ]; then
    print_success "Outputs file exists"
else
    print_error "outputs.tf not found"
    ((VALIDATION_ERRORS++))
fi

# Test 2: Check Module Structure
print_header "2. Validating Module Structure"

REQUIRED_MODULES=("networking" "security" "database" "load_balancer" "ecs" "monitoring" "security_hardening")

for module in "${REQUIRED_MODULES[@]}"; do
    if [ -d "modules/$module" ]; then
        print_success "Module '$module' directory exists"
        
        # Check required files in each module
        for file in "main.tf" "variables.tf" "outputs.tf"; do
            if [ -f "modules/$module/$file" ]; then
                print_success "  - $file exists in $module"
            else
                print_error "  - $file missing in $module"
                ((VALIDATION_ERRORS++))
            fi
        done
    else
        print_error "Module '$module' directory missing"
        ((VALIDATION_ERRORS++))
    fi
done

# Test 3: Check Environment Configurations
print_header "3. Validating Environment Configurations"

ENVIRONMENTS=("demo" "dev" "prod")

for env in "${ENVIRONMENTS[@]}"; do
    if [ -f "environments/$env.tfvars" ]; then
        print_success "Environment '$env' configuration exists"
        
        # Check for required variables in each environment
        REQUIRED_VARS=("environment" "aws_region" "container_cpu" "container_memory")
        
        for var in "${REQUIRED_VARS[@]}"; do
            if grep -q "^$var\s*=" "environments/$env.tfvars"; then
                print_success "  - Variable '$var' configured in $env"
            else
                print_warning "  - Variable '$var' not found in $env"
                ((VALIDATION_WARNINGS++))
            fi
        done
    else
        print_error "Environment '$env' configuration missing"
        ((VALIDATION_ERRORS++))
    fi
done

# Test 4: Check Backend Configuration
print_header "4. Validating Backend Configuration"

if [ -d "backend" ]; then
    print_success "Backend configuration directory exists"
    
    BACKEND_FILES=("main.tf" "variables.tf" "outputs.tf")
    for file in "${BACKEND_FILES[@]}"; do
        if [ -f "backend/$file" ]; then
            print_success "  - Backend $file exists"
        else
            print_error "  - Backend $file missing"
            ((VALIDATION_ERRORS++))
        fi
    done
else
    print_warning "Backend configuration directory not found"
    print_info "  - This is optional but recommended for production use"
    ((VALIDATION_WARNINGS++))
fi

# Test 5: Check for Common Configuration Issues
print_header "5. Checking for Common Configuration Issues"

# Check for hardcoded values that should be variables
if grep -r "us-east-1" --include="*.tf" modules/ > /dev/null 2>&1; then
    print_warning "Hardcoded AWS region found in modules"
    print_info "  - Consider using variables for AWS region"
    ((VALIDATION_WARNINGS++))
else
    print_success "No hardcoded AWS regions in modules"
fi

# Check for TODO comments
TODO_COUNT=$(grep -r "TODO\|FIXME" --include="*.tf" . | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
    print_warning "Found $TODO_COUNT TODO/FIXME comments"
    print_info "  - Review and address TODO items before production deployment"
    ((VALIDATION_WARNINGS++))
else
    print_success "No TODO/FIXME comments found"
fi

# Test 6: Check Resource Naming Consistency
print_header "6. Validating Resource Naming Consistency"

# Check for consistent use of name_prefix
if grep -r "name_prefix" --include="*.tf" modules/ > /dev/null 2>&1; then
    print_success "Consistent naming prefix usage found"
else
    print_warning "No consistent naming prefix usage found"
    ((VALIDATION_WARNINGS++))
fi

# Test 7: Security Configuration Validation
print_header "7. Validating Security Configuration"

# Check for security group configurations
if [ -f "modules/security/main.tf" ]; then
    if grep -q "ingress" "modules/security/main.tf"; then
        print_success "Security group ingress rules configured"
    else
        print_warning "No ingress rules found in security module"
        ((VALIDATION_WARNINGS++))
    fi
    
    if grep -q "egress" "modules/security/main.tf"; then
        print_success "Security group egress rules configured"
    else
        print_warning "No egress rules found in security module"
        ((VALIDATION_WARNINGS++))
    fi
fi

# Check for WAF configuration
if [ -f "modules/security_hardening/main.tf" ]; then
    if grep -q "aws_wafv2_web_acl" "modules/security_hardening/main.tf"; then
        print_success "WAF Web ACL configuration found"
    else
        print_error "WAF configuration missing in security hardening module"
        ((VALIDATION_ERRORS++))
    fi
fi

# Test 8: Monitoring Configuration Validation
print_header "8. Validating Monitoring Configuration"

if [ -f "modules/monitoring/main.tf" ]; then
    if grep -q "aws_cloudwatch_dashboard" "modules/monitoring/main.tf"; then
        print_success "CloudWatch dashboard configuration found"
    else
        print_warning "No CloudWatch dashboard found in monitoring module"
        ((VALIDATION_WARNINGS++))
    fi
    
    if grep -q "aws_cloudwatch_metric_alarm" "modules/monitoring/main.tf"; then
        print_success "CloudWatch alarms configuration found"
    else
        print_warning "No CloudWatch alarms found in monitoring module"
        ((VALIDATION_WARNINGS++))
    fi
fi

# Test 9: File Permissions and Structure
print_header "9. Checking File Permissions and Structure"

# Check for executable scripts
if [ -f "setup-backend.sh" ]; then
    if [ -x "setup-backend.sh" ]; then
        print_success "Backend setup script is executable"
    else
        print_warning "Backend setup script is not executable"
        print_info "  - Run: chmod +x setup-backend.sh"
        ((VALIDATION_WARNINGS++))
    fi
fi

# Summary
echo ""
echo "=================================================="
print_header "Validation Summary"

if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
    print_success "All validations passed! Infrastructure is ready for deployment."
elif [ $VALIDATION_ERRORS -eq 0 ]; then
    print_warning "Validation completed with $VALIDATION_WARNINGS warnings."
    print_info "Infrastructure can be deployed but consider addressing warnings."
else
    print_error "Validation failed with $VALIDATION_ERRORS errors and $VALIDATION_WARNINGS warnings."
    print_error "Please fix errors before attempting deployment."
fi

echo ""
print_header "Next Steps"

if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo "1. 🏗️  Set up Terraform backend (optional): ./setup-backend.sh"
    echo "2. 🚀 Initialize Terraform: terraform init"
    echo "3. 📋 Plan deployment: terraform plan -var-file=\"environments/demo.tfvars\""
    echo "4. 🎯 Deploy infrastructure: terraform apply -var-file=\"environments/demo.tfvars\""
    echo "5. 🔍 Verify deployment: Check AWS console and application URL"
else
    echo "1. ❌ Fix validation errors listed above"
    echo "2. 🔄 Run validation again: ./validate-infrastructure.sh"
    echo "3. 🚀 Proceed with deployment once all errors are resolved"
fi

echo ""
print_info "For detailed deployment instructions, see: DEPLOYMENT-GUIDE.md"
print_info "For backend setup instructions, see: BACKEND-SETUP.md"

# Exit with error code if there are errors
if [ $VALIDATION_ERRORS -gt 0 ]; then
    exit 1
else
    exit 0
fi
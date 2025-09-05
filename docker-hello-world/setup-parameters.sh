#!/bin/bash

# AWS Systems Manager Parameter Store Setup Script
# Run this script to create all required parameters for the guestbook application

echo "Setting up AWS SSM Parameters for Guestbook Application..."

# Database Configuration
echo "Creating database parameters..."
aws ssm put-parameter --name "/guestbook/db/host" --value "postgres" --type "String" --overwrite
aws ssm put-parameter --name "/guestbook/db/name" --value "guestbook_db" --type "String" --overwrite
aws ssm put-parameter --name "/guestbook/db/user" --value "app_user" --type "String" --overwrite
aws ssm put-parameter --name "/guestbook/db/password" --value "joemama" --type "SecureString" --overwrite
aws ssm put-parameter --name "/guestbook/db/port" --value "5432" --type "String" --overwrite

# AWS Configuration
echo "Creating AWS service parameters..."
aws ssm put-parameter --name "/guestbook/aws/region" --value "us-east-1" --type "String" --overwrite
aws ssm put-parameter --name "/guestbook/sqs/queue-url" --value "https://sqs.us-east-1.amazonaws.com/027660363574/guestbook-notifications" --type "String" --overwrite

# SES Email Configuration  
echo "Creating SES email parameters..."
aws ssm put-parameter --name "/guestbook/ses/from-email" --value "syvertsene37@gmail.com" --type "String" --overwrite
aws ssm put-parameter --name "/guestbook/ses/to-email" --value "syvertsene37@gmail.com" --type "String" --overwrite

echo ""
echo "✅ All parameters created successfully!"
echo ""
echo "To verify parameters were created, run:"
echo "aws ssm get-parameters-by-path --path '/guestbook' --recursive"
echo ""
echo "To view a specific parameter:"
echo "aws ssm get-parameter --name '/guestbook/db/password' --with-decryption"
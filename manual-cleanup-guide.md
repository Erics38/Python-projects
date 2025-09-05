# Manual AWS Console Cleanup Guide

The batch scripts aren't working due to complex dependencies. Use the AWS Console instead:

## Step 1: Go to AWS Console
1. Open https://console.aws.amazon.com
2. Make sure you're in **us-east-1** region

## Step 2: Delete VPC Endpoints
1. Go to **VPC** service
2. Click **Endpoints** in left menu
3. Select all endpoints with "guestbook" or "ecr/s3" in name
4. Click **Actions** → **Delete VPC endpoints**
5. Wait 2-3 minutes

## Step 3: Delete Security Groups
1. Still in VPC service
2. Click **Security Groups**
3. Select all groups starting with "guestbook-demo"
4. Click **Actions** → **Delete security groups**
5. If errors, wait 5 minutes and try again

## Step 4: Delete VPCs
1. Click **Your VPCs**
2. Select all VPCs with "guestbook-demo" name (NOT the default VPC)
3. Click **Actions** → **Delete VPC**
4. This will delete subnets, route tables, internet gateways automatically

## Alternative: Use AWS CLI Nuke Tool
Install aws-nuke tool for complete cleanup:
```bash
# Download aws-nuke from GitHub
# Create config file excluding default VPC
# Run: aws-nuke -c config.yml --profile your-profile
```

## Quick Manual Commands
If you prefer CLI, run these one by one:

```bash
# Delete specific VPCs (replace with your VPC IDs)
aws ec2 delete-vpc --vpc-id vpc-0899032133b559e32
aws ec2 delete-vpc --vpc-id vpc-095586e614ea1a60a
aws ec2 delete-vpc --vpc-id vpc-038ed6ddc113dfc3f
aws ec2 delete-vpc --vpc-id vpc-0f17184ddbfe50ce2
```

The AWS Console method is most reliable for complex dependency cleanup.
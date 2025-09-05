@echo off
cd docker-hello-world\infrastructure

echo === Testing Terraform Setup ===
terraform version
echo.

echo === Initializing Terraform ===
terraform init
echo.

echo === Validating Configuration ===
terraform validate
echo.

echo === Planning Deployment ===
terraform plan
echo.

echo === Ready to deploy! ===
echo Run: terraform apply
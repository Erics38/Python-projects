# Outputs for Terraform backend configuration

output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_configuration" {
  description = "Backend configuration block to use in main Terraform configuration"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "guestbook/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
  }
}

output "backend_config_text" {
  description = "Ready-to-use backend configuration text"
  value = <<-EOT
backend "s3" {
  bucket         = "${aws_s3_bucket.terraform_state.id}"
  key            = "guestbook/terraform.tfstate"
  region         = "${var.aws_region}"
  encrypt        = true
  dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
}
EOT
}
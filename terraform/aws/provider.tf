# AWS provider
# Auth is intentionally not configured here so Terraform uses the standard AWS credential chain:
# - AWS_PROFILE / ~/.aws/credentials
# - environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)
# - IAM role (recommended on CI)
provider "aws" {
  region = var.aws_region
}

provider "tls" {}


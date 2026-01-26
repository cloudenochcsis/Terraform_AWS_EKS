provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "eks-infrastructure"
      Environment = "production"
      ManagedBy   = "Terraform"
      Purpose     = "Backend Infrastructure"
    }
  }
}

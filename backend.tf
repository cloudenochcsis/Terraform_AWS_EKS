terraform {
  backend "s3" {
    bucket               = "cloudenoch-open-telemetry-terraform-eks-state-7x9k2m"
    key                  = "terraform.tfstate"
    region               = "us-west-2"
    dynamodb_table       = "terraform-eks-state-locks"
    encrypt              = true
    use_lockfile         = false
    workspace_key_prefix = "workspaces"
  }
}

# EKS Infrastructure with Terraform - UPDATED

🎉 **Now using the latest Terraform AWS modules and best practices!**

## What's New

This infrastructure has been updated to use:

- ✅ **AWS Provider 6.28.0** (previously ~5.0)
- ✅ **Official terraform-aws-modules/vpc** version 6.6.0 (replaces custom module)
- ✅ **Official terraform-aws-modules/eks** version 21.12.0 (replaces custom module)
- ✅ **Kubernetes 1.31** support (latest stable version)
- ✅ **Enhanced security** with bucket_key_enabled, server-side encryption for DynamoDB
- ✅ **Improved lifecycle management** for S3 state versioning
- ✅ **Latest EKS addons** including Pod Identity Agent

## Features

### Infrastructure
- **Multi-AZ VPC** with automatic AZ selection
- **EKS Cluster** with managed node groups
- **KMS Encryption** for cluster secrets
- **VPC Flow Logs** for network monitoring
- **S3 + DynamoDB backend** for state management

### Security
- IMDSv2 enforced on all EC2 instances
- Encryption at rest for S3 and DynamoDB
- Private subnets for worker nodes
- KMS key rotation enabled
- VPC Flow Logs for audit

### EKS Features
- IRSA (IAM Roles for Service Accounts) enabled
- Latest EKS addons: CoreDNS, kube-proxy, VPC-CNI, Pod Identity Agent
- CloudWatch logging enabled
- API & ConfigMap authentication mode

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- kubectl installed

## Quick Start

### 1. Initialize Backend (First Time)

```bash
cd backend
terraform init
terraform apply
cd ..
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name my-eks-cluster
kubectl get nodes
```

## Module Versions

| Component | Source | Version |
|-----------|--------|---------|
| AWS Provider | hashicorp/aws | ~> 6.28 |
| VPC Module | terraform-aws-modules/vpc/aws | ~> 6.6 |
| EKS Module | terraform-aws-modules/eks/aws | ~> 21.12 |

## Key Changes from Previous Version

### Removed Custom Modules
The custom `./modules/vpc` and `./modules/eks` directories are **no longer needed**. The official modules provide:
- Better maintenance and updates
- More features out-of-the-box
- Community support
- Regular security updates

### Updated Variable Structure
Node groups now use a simpler structure:

```hcl
node_groups = {
  general = {
    name             = "general"
    instance_type    = "t3.medium"
    min_size         = 1
    max_size         = 4
    desired_capacity = 2
    disk_size        = 20
    labels = {
      role = "general"
    }
  }
}
```

### New Outputs
Additional outputs for better integration:

- `cluster_arn` - Full ARN of the cluster
- `cluster_oidc_issuer_url` - For IRSA configuration
- `oidc_provider_arn` - OIDC provider ARN
- `configure_kubectl` - Ready-to-use kubectl configuration command

## Configuration Examples

### Production Setup

```hcl
# terraform.tfvars
environment              = "prod"
cluster_version          = "1.31"
enable_nat_gateway       = true
single_nat_gateway       = false  # Redundant NAT Gateways
enable_cluster_encryption = true
enable_flow_logs         = true

node_groups = {
  general = {
    instance_type    = "t3.medium"
    min_size         = 2
    max_size         = 10
    desired_capacity = 3
  }
  compute = {
    instance_type    = "c5.2xlarge"
    min_size         = 1
    max_size         = 20
    desired_capacity = 2
  }
}
```

### Development/Cost-Optimized Setup

```hcl
# terraform.tfvars
environment              = "dev"
cluster_version          = "1.31"
enable_nat_gateway       = true
single_nat_gateway       = true   # Single NAT Gateway
enable_cluster_encryption = true
enable_flow_logs         = false  # Optional for dev

node_groups = {
  general = {
    instance_type    = "t3.small"
    min_size         = 1
    max_size         = 3
    desired_capacity = 1
  }
}
```

## Migration Guide

If you're upgrading from the old version:

### 1. Backup Your State

```bash
terraform state pull > terraform.tfstate.backup
```

### 2. Update Configuration

The new `main.tf`, `variables.tf`, and `outputs.tf` files are already updated.

### 3. Initialize New Modules

```bash
terraform init -upgrade
```

### 4. Review Plan Carefully

```bash
terraform plan
```

⚠️ **Note**: Switching modules will cause resource recreation. For production, consider:
- Using `terraform state mv` to preserve resources
- Planning a maintenance window
- Testing in a non-production environment first

### 5. Apply Changes

```bash
terraform apply
```

## Upgrading Kubernetes Version

To upgrade your cluster:

1. Update `cluster_version` in variables
2. Run `terraform plan` to review changes
3. Apply the upgrade: `terraform apply`
4. Update node groups if needed

```hcl
cluster_version = "1.32"
```

## Troubleshooting

### Module Download Issues

```bash
terraform init -upgrade
terraform get -update
```

### State Lock Issues

```bash
# View locks
aws dynamodb scan --table-name terraform-eks-state-locks

# Force unlock (use carefully)
terraform force-unlock <LOCK_ID>
```

### EKS Access Issues

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name my-eks-cluster

# Verify access
kubectl get svc

# Check IAM identity
aws sts get-caller-identity
```

## Best Practices

1. **State Management**: Always use remote state (S3 + DynamoDB)
2. **Version Control**: Pin module versions in production
3. **Secrets**: Never commit `terraform.tfvars` with sensitive data
4. **Testing**: Test changes in dev/staging first
5. **Documentation**: Keep this README updated with your changes

## Outputs Reference

After `terraform apply`, you'll see:

```
configure_kubectl = "aws eks update-kubeconfig --region us-west-2 --name my-eks-cluster"
cluster_endpoint = "https://xxx.eks.us-west-2.amazonaws.com"
cluster_name = "my-eks-cluster"
vpc_id = "vpc-xxx"
```

Use these outputs in your CI/CD pipelines or documentation.

## Clean Up

To destroy all resources:

```bash
# Delete Kubernetes resources first
kubectl delete all --all -A

# Destroy infrastructure
terraform destroy

# Optional: Destroy backend
cd backend && terraform destroy
```

## Support & References

- [Terraform AWS Provider Changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md)
- [EKS Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [VPC Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## Contributing

When making changes:
1. Test in a separate environment
2. Update documentation
3. Follow Terraform style guide
4. Review security implications

---

**Updated**: January 2026 with latest Terraform modules and AWS provider

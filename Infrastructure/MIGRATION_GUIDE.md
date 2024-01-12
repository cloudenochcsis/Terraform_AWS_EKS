# Terraform Infrastructure Update Summary

## Overview
Your Terraform infrastructure has been updated to use the latest official AWS modules and provider versions, replacing custom modules with well-maintained community modules.

## Key Updates

### 1. AWS Provider
- **Before**: `~> 5.0`
- **After**: `~> 6.28`
- **Why**: Latest features, security patches, and bug fixes

### 2. VPC Module
- **Before**: Custom module in `./modules/vpc`
- **After**: `terraform-aws-modules/vpc/aws` version `~> 6.6`
- **Benefits**:
  - 162M+ downloads, battle-tested
  - Regular updates and community support
  - More features (Flow Logs, IPAM, etc.)
  - Better documentation

### 3. EKS Module
- **Before**: Custom module in `./modules/eks`
- **After**: `terraform-aws-modules/eks/aws` version `~> 21.12`
- **Benefits**:
  - 130M+ downloads, industry standard
  - Latest EKS features (Pod Identity, Auto Mode ready)
  - Better IRSA support
  - More addons included

### 4. Kubernetes Version
- **Updated**: From `1.30` to `1.31` (latest stable)

## Files Modified

### ✅ Updated Files
1. **main.tf** - Complete rewrite using official modules
2. **variables.tf** - Updated variable structure for new modules
3. **outputs.tf** - Enhanced outputs with more useful information
4. **backend/main.tf** - Added encryption and lifecycle improvements

### 📝 New Files Created
1. **README_UPDATED.md** - Comprehensive documentation
2. **MIGRATION_GUIDE.md** - This file

### ⚠️ Custom Modules
The following directories are **no longer needed** with the new configuration:
- `modules/vpc/` - Replaced by terraform-aws-modules/vpc
- `modules/eks/` - Replaced by terraform-aws-modules/eks

**Note**: Don't delete these yet if you have an existing deployment. See migration steps below.

## New Features Available

### 1. Enhanced Security
```hcl
# S3 bucket key enabled for cost optimization
bucket_key_enabled = true

# DynamoDB server-side encryption
server_side_encryption {
  enabled = true
}

# IMDSv2 enforced
metadata_options = {
  http_tokens = "required"
}
```

### 2. Automatic AZ Selection
```hcl
# No need to hardcode AZs anymore
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
```

### 3. Latest EKS Addons
```hcl
cluster_addons = {
  coredns                = { most_recent = true }
  kube-proxy            = { most_recent = true }
  vpc-cni               = { most_recent = true }
  eks-pod-identity-agent = { most_recent = true }
}
```

### 4. IRSA Support
```hcl
enable_irsa = true
```

## What You Need to Know

### Variable Changes

#### Old Structure (node_groups):
```hcl
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 2
      max_size     = 4
      min_size     = 1
    }
  }
}
```

#### New Structure:
```hcl
node_groups = {
  general = {
    name             = "general"
    instance_type    = "t3.medium"
    min_size         = 1
    max_size         = 4
    desired_capacity = 2
    disk_size        = 20
    labels           = { role = "general" }
  }
}
```

### Removed Variables
- `availability_zones` - Now automatically detected

### New Outputs
- `cluster_arn`
- `cluster_oidc_issuer_url`
- `oidc_provider_arn`
- `configure_kubectl`
- `vpc_cidr_block`
- `nat_gateway_ids`

## Migration Paths

### Path 1: Fresh Deployment (Recommended for Dev/Test)

If you can recreate your infrastructure:

```bash
# 1. Backup current state
terraform state pull > old-state-backup.json

# 2. Destroy old infrastructure (CAUTION!)
terraform destroy

# 3. Update to new code (already done)

# 4. Deploy new infrastructure
terraform init -upgrade
terraform plan
terraform apply
```

### Path 2: State Migration (For Production)

If you need to preserve existing resources:

**⚠️ ADVANCED - Requires careful planning**

```bash
# 1. Backup everything
terraform state pull > state-backup.json
aws s3 cp s3://your-bucket/terraform.tfstate s3://your-bucket/terraform.tfstate.backup

# 2. Create new workspace
terraform workspace new migration

# 3. Import resources to new modules
# This is complex and resource-specific
# Example for VPC:
terraform import 'module.vpc.aws_vpc.this[0]' vpc-xxxxx

# 4. Carefully plan and apply
terraform plan
terraform apply
```

### Path 3: Blue-Green Deployment (Safest for Production)

1. Deploy new infrastructure with a different cluster name
2. Migrate workloads to new cluster
3. Decommission old cluster
4. Update DNS/load balancers

```hcl
# In terraform.tfvars
cluster_name = "my-eks-cluster-v2"
```

## Testing Checklist

Before migrating production:

- [ ] Test in development environment first
- [ ] Backup state files
- [ ] Review `terraform plan` output carefully
- [ ] Verify all outputs are available
- [ ] Test kubectl access
- [ ] Verify workloads can schedule
- [ ] Check IAM roles and permissions
- [ ] Validate networking (pods can communicate)
- [ ] Test external connectivity

## Rollback Plan

If something goes wrong:

### Option 1: Restore State
```bash
# Restore from backup
aws s3 cp s3://your-bucket/terraform.tfstate.backup s3://your-bucket/terraform.tfstate

# Pull and verify
terraform state pull > current-state.json
terraform plan
```

### Option 2: Re-apply Old Code
```bash
# Checkout previous version from git
git checkout <previous-commit> Infrastructure/

# Re-initialize and apply
terraform init
terraform plan
terraform apply
```

## Post-Migration Tasks

After successful migration:

1. **Update CI/CD pipelines** with new module versions
2. **Update documentation** with new outputs
3. **Archive old modules** (don't delete yet)
   ```bash
   mkdir -p archive/old-modules
   mv modules archive/old-modules/
   ```
4. **Update team** on new variable structure
5. **Monitor cluster** for 24-48 hours
6. **Clean up old backups** after stability confirmed

## Common Issues & Solutions

### Issue 1: Module Download Fails
```bash
# Solution
terraform init -upgrade
terraform get -update
```

### Issue 2: State Lock
```bash
# Check locks
aws dynamodb scan --table-name terraform-eks-state-locks

# Force unlock if needed
terraform force-unlock <LOCK_ID>
```

### Issue 3: Missing Variables
```
Error: variable not declared
```
**Solution**: Check variables.tf - some variables were renamed or removed

### Issue 4: Resource Already Exists
```
Error: resource already exists
```
**Solution**: Import the resource or use state migration

## Terraform Commands Reference

```bash
# Initialize with new modules
terraform init -upgrade

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -out=tfplan

# Apply specific plan
terraform apply tfplan

# Show current state
terraform show

# List resources
terraform state list

# View specific resource
terraform state show 'module.vpc.aws_vpc.this[0]'
```

## Getting Help

If you encounter issues:

1. Check Terraform documentation: https://registry.terraform.io/
2. Review module issues:
   - VPC: https://github.com/terraform-aws-modules/terraform-aws-vpc/issues
   - EKS: https://github.com/terraform-aws-modules/terraform-aws-eks/issues
3. AWS EKS documentation: https://docs.aws.amazon.com/eks/

## Next Steps

1. **Review** all changes in this guide
2. **Choose** migration path (Fresh/State Migration/Blue-Green)
3. **Test** in non-production environment
4. **Plan** maintenance window for production
5. **Execute** migration with team oversight
6. **Verify** all functionality post-migration
7. **Document** any custom modifications needed

## Recommendations

### For Development Environments
✅ Use **Path 1 (Fresh Deployment)** - Fastest and cleanest

### For Staging Environments
✅ Use **Path 2 (State Migration)** - Good practice for production migration

### For Production Environments
✅ Use **Path 3 (Blue-Green)** - Safest, zero downtime

---

**Remember**: Always test in a non-production environment first!

**Questions?** Review the README_UPDATED.md for detailed documentation.

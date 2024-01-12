# AWS EKS Infrastructure with Terraform

Production-ready Terraform infrastructure for deploying an Amazon EKS cluster with VPC networking, optimized for security, cost efficiency, and high availability.

## Architecture Overview

This Terraform configuration provisions:

- **VPC**: Multi-AZ VPC with public and private subnets
- **EKS Cluster**: Kubernetes cluster with configurable node groups
- **Security**: KMS encryption, VPC Flow Logs, IAM roles, and security groups
- **High Availability**: Multi-AZ deployment with optional NAT Gateway redundancy
- **Cost Optimization**: Optional single NAT Gateway for dev/staging environments

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions to create VPC, EKS, IAM, and KMS resources

## Project Structure

```
Infrastructure/
├── main.tf                    # Root module configuration
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── terraform.tfvars.example   # Example variables file
├── backend/                   # Backend state configuration
│   ├── main.tf
│   └── outputs.tf
└── modules/
    ├── vpc/                   # VPC module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eks/                   # EKS module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Quick Start

### 1. Configure Backend (First Time Only)

The backend creates an S3 bucket and DynamoDB table for Terraform state management.

```bash
cd backend
terraform init
terraform plan
terraform apply
cd ..
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
region       = "us-west-2"
project_name = "my-project"
environment  = "dev"
cluster_name = "my-eks-cluster"
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure kubectl

After deployment, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --region us-west-2 --name my-eks-cluster
```

Verify access:

```bash
kubectl get nodes
```

## Configuration Options

### Cost Optimization

For development/staging environments, reduce costs by using a single NAT Gateway:

```hcl
single_nat_gateway = true
```

This saves ~$32/month per additional NAT Gateway but reduces availability.

### Security Features

**KMS Encryption** (enabled by default):
```hcl
enable_cluster_encryption = true
```

**VPC Flow Logs** (enabled by default):
```hcl
enable_flow_logs = true
```

**Private Cluster Endpoint**:
```hcl
cluster_endpoint_public_access = false
```

### Node Groups

Configure multiple node groups for different workload types:

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
  spot = {
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "SPOT"
    scaling_config = {
      desired_size = 1
      max_size     = 3
      min_size     = 0
    }
  }
}
```

## Module Documentation

### VPC Module

Creates a multi-AZ VPC with:
- Public subnets with Internet Gateway
- Private subnets with NAT Gateway(s)
- Route tables and associations
- VPC Flow Logs (optional)
- Proper EKS tags for subnet discovery

**Key Variables**:
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `availability_zones`: List of AZs to use
- `enable_nat_gateway`: Enable/disable NAT Gateway
- `single_nat_gateway`: Use single NAT Gateway for cost savings

### EKS Module

Creates an EKS cluster with:
- IAM roles and policies
- KMS encryption for secrets (optional)
- CloudWatch logging
- Configurable node groups
- Security groups

**Key Variables**:
- `cluster_version`: Kubernetes version (default: 1.30)
- `enable_cluster_encryption`: Enable KMS encryption
- `cluster_endpoint_public_access`: Public endpoint access

## Outputs

After applying, Terraform outputs important values:

```bash
terraform output cluster_endpoint
terraform output cluster_name
terraform output vpc_id
```

To view sensitive outputs:

```bash
terraform output -raw cluster_certificate_authority_data | base64 -d
```

## Best Practices

### Security

1. Enable cluster encryption for production workloads
2. Use private endpoint access for sensitive environments
3. Enable VPC Flow Logs for network monitoring
4. Review IAM policies regularly
5. Use secrets management (AWS Secrets Manager or Parameter Store)

### High Availability

1. Deploy across multiple availability zones
2. Use multiple NAT Gateways in production
3. Configure appropriate node group sizing
4. Implement pod disruption budgets

### Cost Optimization

1. Use spot instances for non-critical workloads
2. Enable cluster autoscaling
3. Use single NAT Gateway in dev/staging
4. Right-size node instance types
5. Set appropriate log retention periods

### Monitoring

1. Enable CloudWatch Container Insights
2. Configure VPC Flow Logs
3. Enable EKS control plane logging
4. Set up CloudWatch alarms

## Maintenance

### Updating Kubernetes Version

1. Update the `cluster_version` variable
2. Run `terraform plan` to review changes
3. Apply with `terraform apply`
4. Update node groups (Terraform handles this automatically)

### Scaling Node Groups

Terraform ignores changes to `desired_size` to avoid conflicts with cluster autoscaler. To change capacity:

```bash
aws eks update-nodegroup-config \
  --cluster-name my-eks-cluster \
  --nodegroup-name general \
  --scaling-config desiredSize=3
```

### Destroying Infrastructure

To tear down all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the EKS cluster and VPC.

## Troubleshooting

### Common Issues

**Issue**: Terraform cannot find backend bucket
```bash
cd backend && terraform apply
```

**Issue**: kubectl cannot connect to cluster
```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

**Issue**: Nodes not joining cluster
- Check VPC and subnet tags
- Verify NAT Gateway is running
- Review node group IAM role policies

**Issue**: Cost is higher than expected
- Reduce NAT Gateways with `single_nat_gateway = true`
- Use spot instances
- Review CloudWatch log retention

## Security Considerations

### State File Security

- State files are encrypted in S3 with AES256
- S3 bucket has versioning enabled
- Public access is blocked
- DynamoDB table has point-in-time recovery

### Cluster Security

- Secrets encrypted with KMS
- Private endpoint access available
- VPC Flow Logs enabled
- IAM roles follow least privilege

### Network Security

- Private subnets for worker nodes
- Security groups restrict traffic
- Network ACLs can be added if needed

## Cost Estimate

Approximate monthly costs (us-west-2):

| Resource | Configuration | Cost |
|----------|--------------|------|
| EKS Cluster | 1 cluster | $73 |
| EC2 (t3.medium) | 2 nodes | ~$60 |
| NAT Gateway | 3 gateways | ~$97 |
| Data Transfer | Minimal | ~$10 |
| **Total** | | **~$240/month** |

Cost savings with `single_nat_gateway = true`: ~$64/month

## Contributing

When making changes:
1. Run `terraform fmt` to format code
2. Run `terraform validate` to check syntax
3. Test in a development environment first
4. Update documentation as needed

## License

This infrastructure code is provided as-is for educational and production use.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS EKS documentation
3. Check Terraform AWS provider documentation

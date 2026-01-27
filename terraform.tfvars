# AWS Configuration
region = "us-west-2"

# Project Metadata
project_name = "Open-Telemetry-eks-infrastructure"
environment  = "dev" # Options: dev, staging, prod
owner        = "DevOps Team"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

# VPC Features - Cost Optimization
enable_nat_gateway = true
single_nat_gateway = true # COST SAVINGS: Use single NAT Gateway for dev/staging (~$64/month saved)
enable_flow_logs   = true

# EKS Cluster Configuration
cluster_name    = "open-telemetry-eks-cluster"
cluster_version = "1.34"

# EKS Security
enable_cluster_encryption      = true
cluster_endpoint_public_access = true # Set to false for private-only access

# ============================================================================
# COST-OPTIMIZED NODE GROUPS
# ============================================================================
# This configuration demonstrates multiple cost optimization strategies:
# 1. Mixed instance types (AMD instances are ~10% cheaper)
# 2. Spot instances (up to 90% savings)
# 3. ARM-based Graviton instances (up to 40% savings)
# 4. Right-sized disk volumes
# 5. Workload-specific node pools with taints
# ============================================================================

node_groups = {
  # -------------------------------------------------------------------------
  # OPTION 1: Cost-Optimized ON-DEMAND (Standard Workloads)
  # Estimated cost: ~$60/month for 2 nodes
  # -------------------------------------------------------------------------
  general = {
    name             = "general"
    instance_type    = "t3.medium"
    min_size         = 2
    max_size         = 4
    desired_capacity = 2
    disk_size        = 20 # Minimal disk size for cost savings
    labels = {
      workload-type = "general"
      cost-profile  = "balanced"
    }
    taints = {} # No taints - accepts all workloads
    tags   = {}
  }
}

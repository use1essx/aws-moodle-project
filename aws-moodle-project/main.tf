# =====================
# VPC Module
# =====================
module "vpc" {
  source = "./modules/vpc"
}

# =====================
# EKS Module (DISABLED - using minimal setup below)
# =====================
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "19.21.0"
#
#   cluster_name    = "moodle-eks-cluster"
#   cluster_version = "1.29"
#
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets
#
#   create_iam_role = false
#   iam_role_arn    = var.eks_cluster_role_arn
#
#   eks_managed_node_groups = {
#     default = {
#       desired_size   = 1
#       min_size       = 1
#       max_size       = 1
#       instance_types = ["t3.micro"]
#       capacity_type  = "ON_DEMAND"
#       subnets        = module.vpc.private_subnets
#       create_iam_role = false
#       role_arn        = var.eks_node_role_arn
#     }
#   }
#
#   tags = {
#     Environment = "moodle"
#     Project     = "ITP4122"
#   }
# }

# =====================
# Minimal EKS Setup (No IAM lookups)
# =====================
resource "aws_eks_cluster" "this" {
  name     = "moodle-eks-cluster"
  role_arn = var.eks_cluster_role_arn
  version  = "1.29"

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  depends_on = [module.vpc]
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = module.vpc.private_subnets
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  instance_types = ["t3.micro"]
  depends_on = [aws_eks_cluster.this]
}

# =====================
# RDS Module
# =====================
module "rds" {
  source              = "./modules/rds"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnets
}

# =====================
# Helm Moodle Module
# =====================
module "helm_moodle" {
  source           = "./modules/helm_moodle"
  cluster_name     = aws_eks_cluster.this.name
  cluster_endpoint = aws_eks_cluster.this.endpoint
  cluster_ca       = aws_eks_cluster.this.certificate_authority[0].data
  rds_endpoint     = module.rds.db_endpoint
  rds_password     = module.rds.db_password
}

# =====================
# EKS Data Sources (for kubectl/Helm)
# =====================
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "auth" {
  name = aws_eks_cluster.this.name
}

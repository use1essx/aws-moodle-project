module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.3"  # latest stable as of 2024

  cluster_name    = "moodle-eks-cluster"
  cluster_version = "1.29"

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  enable_irsa              = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    instance_types = ["t3.micro"]
    ami_type       = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"
      subnets        = var.private_subnet_ids
      role_arn       = var.node_role_arn
    }
  }

  iam_role_arn = var.iam_role_arn

  tags = {
    Environment = "moodle"
    Project     = "ITP4122"
  }
}

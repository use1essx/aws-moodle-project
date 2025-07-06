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
# Security Groups
# =====================
resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow K8s API (adjust as needed)
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id] # Allow HTTP from ALB
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id] # Allow HTTPS from ALB
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id] # Only allow from EKS nodes
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================
# Minimal EKS Setup (No IAM lookups)
# =====================
resource "aws_eks_cluster" "this" {
  name     = "moodle-eks-cluster"
  role_arn = var.eks_cluster_role_arn
  version  = "1.29"

  vpc_config {
    subnet_ids = module.vpc.private_subnets
    security_group_ids = [aws_security_group.eks_nodes.id]
  }

  depends_on = [module.vpc]
}

# =====================
# EC2 Key Pair for EKS Nodes (Automated)
# =====================
resource "tls_private_key" "eks" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks" {
  key_name   = "eks-key"
  public_key = tls_private_key.eks.public_key_openssh
}

resource "local_file" "eks_private_key" {
  content         = tls_private_key.eks.private_key_pem
  filename        = "${path.module}/eks-key.pem"
  file_permission = "0400"
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = module.vpc.private_subnets
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  instance_types = ["t3.micro"]
  remote_access {
    ec2_ssh_key = aws_key_pair.eks.key_name
    source_security_group_ids = [aws_security_group.eks_nodes.id]
  }
  depends_on = [aws_eks_cluster.this]
}

# =====================
# RDS Module
# =====================
module "rds" {
  source                = "./modules/rds"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  rds_security_group_id = aws_security_group.rds.id
  rds_instance_count    = 2
}

# =====================
# StorageClass for EKS Persistent Volumes (gp3)
# =====================
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  parameters = {
    type = "gp3"
  }
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
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

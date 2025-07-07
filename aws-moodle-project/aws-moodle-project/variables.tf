variable "region" {
  default = "us-east-1"
}

variable "eks_cluster_role_arn" {
  description = "The ARN of the pre-existing EKS Cluster IAM role."
  type        = string
}

variable "eks_node_role_arn" {
  description = "The ARN of the pre-existing EKS Node IAM role."
  type        = string
}

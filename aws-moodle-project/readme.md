# 📘 AWS Moodle Project – Full Terraform & Helm Deployment

## 2️⃣A. AWS Learner Lab: Find and Set EKS IAM Role ARNs (Required)

In AWS Learner Lab, you must use the pre-existing IAM roles for EKS. You cannot create or edit IAM roles. Follow these steps before running Terraform:

### 1. Find the Required Role ARNs Using AWS CLI

Open AWS CloudShell or your terminal and run:

```sh
# Find the EKS Cluster Role ARN
aws iam list-roles --query "Roles[?contains(RoleName, 'LabEksClusterRole')].Arn" --output text

# Find the EKS Node Role ARN
aws iam list-roles --query "Roles[?contains(RoleName, 'LabEksNodeRole')].Arn" --output text
```

Copy the ARNs that are output by these commands.

### 2. Set the ARNs as Environment Variables

In your terminal, run:

```sh
export TF_VAR_eks_cluster_role_arn="arn:aws:iam::...:role/..."
export TF_VAR_eks_node_role_arn="arn:aws:iam::...:role/..."
```
*(Replace the ... with the actual ARNs you copied above.)*

Now continue with the Terraform steps below.

## Important: Update IAM Role ARNs

Before running Terraform, open `terraform.tfvars` and set the following variables to the ARNs of your pre-existing IAM roles:

```
eks_cluster_role_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:role/LabEksClusterRole-..."
eks_node_role_arn    = "arn:aws:iam::YOUR_ACCOUNT_ID:role/LabEksNodeRole-..."
```

You can find these ARNs in the AWS IAM console under Roles. 
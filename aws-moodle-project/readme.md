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

## 🚀 One-Line Deployment

```sh
terraform init
terraform apply -auto-approve
```

## 🌐 Access Moodle
- After apply, find the ALB DNS name in the AWS console (EC2 > Load Balancers) or from the Terraform output (if configured).
- Open the DNS in your browser to access Moodle.

## 📈 Scale Moodle Pods
- To scale up Moodle pods (e.g., to 3):
```sh
kubectl scale deployment moodle --replicas=3
```
- Check pods:
```sh
kubectl get pods
```

## 🛡️ Check RDS High Availability
- In AWS Console, go to RDS > Clusters > moodle-aurora-cluster.
- Confirm there are 2 instances (Writer/Reader or Multi-AZ).

## 🎬 Demo Checklist
- [ ] Show VPC, subnets, and security groups in AWS Console
- [ ] Show EKS cluster and node group
- [ ] Show RDS cluster with 2 instances
- [ ] Show ALB and access Moodle in browser
- [ ] Show scaling Moodle pods (multiple pods running)
- [ ] Show ConfigMap/Helm values in use
- [ ] Show one-line deployment (terraform apply)

## 🗺️ System Architecture Diagram
- See the included diagram in the report (or architecture.png if provided) 
# 📘 AWS Moodle Project – Full Terraform & Helm Deployment

This project deploys a **fully functional Moodle LMS** on AWS using:
- **Terraform** for Infrastructure-as-Code (IaC)
- **Amazon EKS** (Kubernetes) for hosting Moodle
- **Bitnami Moodle** container deployed via **Helm**
- **Amazon RDS (MySQL/Aurora)** as the Moodle backend database
- **AWS Load Balancer** for public access

> 🧾 Based on: `ITP4122_EA.docx` project report

---

## 🧱 Architecture Overview

```
┌────────────────────────┐
│     Amazon Route53     │ (Optional)
└────────────┬───────────┘
             ↓
      ┌───────────────┐      ┌──────────────┐
      │  ALB (80/443) │ <--→ │Public Subnets│ (AZ1 + AZ2)
      └──────┬────────┘      └──────────────┘
             ↓
        ┌─────────────┐
        │   EKS Nodes │ ← Helm → Moodle (Bitnami)
        └──────┬──────┘
               ↓
        ┌─────────────┐
        │   RDS MySQL │ (Multi-AZ, private subnets)
        └─────────────┘
```

---

## 📁 Project Structure

```
aws-moodle-project/
├── main.tf                  # Root Terraform file (calls modules)
├── variables.tf             # AWS region and other vars
├── outputs.tf               # Exports Moodle service URL
├── providers.tf             # AWS + Kubernetes providers
├── moodle-values.yaml       # Helm values for Moodle chart
├── deploy-moodle.sh         # Script for manual Moodle deployment (if needed)
└── modules/                 # Modular design
    ├── vpc/                 # VPC, subnets, NAT, routes
    ├── eks/                 # EKS cluster + node group
    ├── rds/                 # RDS MySQL
    └── helm_moodle/         # Helm chart deployment
```

---

# 🚀 Step-by-Step Deployment Guide

## 1️⃣ Prerequisites

| Tool        | Version         | Notes |
|-------------|-----------------|-------|
| Terraform   | >= 1.3          | Install if not present |
| AWS CLI     | Pre-installed   | In AWS CloudShell |
| Helm        | >= 3.0          | Install if not present |
| kubectl     | Pre-installed   | In AWS CloudShell |
| git         | Pre-installed   | In AWS CloudShell |

> **Tip:** In AWS CloudShell, only Terraform and Helm need to be installed. All other tools are pre-installed.

---

## 2️⃣ Install Required Tools (if not present)

```bash
# Install Terraform (example for v1.7.5)
wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform -version

# Install Helm (example for v3)
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version
```

---

## 3️⃣ Clone the Repository and Switch Branch

```bash
git clone https://github.com/use1essx/aws-moodle-project
cd aws-moodle-project
git checkout update_7
cd aws-moodle-project
```

---


## 5️⃣ Initialize Terraform

```bash
terraform init
```

---

## 6️⃣ Plan and Apply Infrastructure

```bash
terraform plan
terraform apply
```
- Type `yes` when prompted.
- Wait 5–10 minutes for AWS resources to be provisioned (VPC, EKS, RDS, etc.).

---

## 7️⃣ Find Required Values for Moodle Deployment

After `terraform apply` completes, you will need:
- **EKS Cluster Name:**
  - Output from Terraform: `module.eks.cluster_name` (or check AWS Console)
- **RDS Endpoint:**
  - Output from Terraform: `module.rds.db_endpoint` (or check AWS Console)
- **DB Password:**
  - Output from Terraform: `module.rds.db_password` (or as set in `moodle-values.yaml`)

---


## 9️⃣ Access Your Moodle Site

- Get the Moodle URL:
  ```bash
  terraform output moodle_url
  # or check the EXTERNAL-IP from the script output
  ```
- Open the URL in your browser.
- Login with:
  - Username: as set in `moodle-values.yaml` (default: `admin`)
  - Password: as set in `moodle-values.yaml`

---

## 🔄 Cleanup (Destroy All Resources)

To avoid AWS charges, destroy all resources when done:
```bash
terraform destroy
```
- Type `yes` when prompted.

---


## 📝 Notes for AWS Learner Lab

- IAM roles for EKS are auto-detected using Terraform data sources.
- You cannot create or edit IAM roles in Learner Lab; use the pre-existing roles.
- Always destroy resources after use to avoid quota issues for your classmates.

---

To set up your `aws-moodle-project` (the Terraform + Kubernetes + Helm Moodle deployment), follow these step-by-step instructions. This guide assumes you are using AWS Learner Lab and have the required permissions.

---

## 1. Prerequisites

- **AWS CLI** installed and configured (with your Learner Lab credentials)
- **kubectl** installed
- **Helm** installed
- **Terraform** installed
- Your AWS Learner Lab account is active

---

## 2. Update Configuration Files

**a. Edit `terraform.tfvars`**

- Replace `ACCOUNT_ID` with your actual AWS Learner Lab account number.
- Replace `vpc_id` and `subnet_ids` with the real VPC and subnet IDs from your Learner Lab environment.

Example:
```hcl
region = "us-east-1"
cluster_name = "moodle-eks-cluster"
cluster_version = "1.29"
cluster_iam_role_arn = "arn:aws:iam::123456789012:role/LabEksClusterRole"
node_role_arn         = "arn:aws:iam::123456789012:role/LabRole"
vpc_id     = "vpc-0abc1234def567890"
subnet_ids = ["subnet-0abc1234def567890", "subnet-0def1234abc567890"]
node_group_desired_capacity = 2
node_group_max_capacity     = 2
node_group_min_capacity     = 1
```

---

## 3. Initialize and Apply Terraform

Open a terminal in the `aws-moodle-project` directory and run:

```bash
terraform init
terraform apply -auto-approve
```

This will provision your EKS cluster and related AWS resources.

---

## 4. Update kubeconfig

After Terraform finishes, update your kubeconfig to connect `kubectl` to your new EKS cluster:

```bash
aws eks update-kubeconfig --name moodle-eks-cluster --region us-east-1
```

---

## 5. Deploy Moodle and Kubernetes Resources

If you have the `deploy-all.sh` script, make it executable and run it:

```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

**If you do not have `deploy-all.sh`, do the following manually:**

a. **Create the namespace and ConfigMap:**
```bash
kubectl create namespace moodle
kubectl apply -f moodle-config.yaml
```

b. **Deploy the Horizontal Pod Autoscaler:**
```bash
kubectl apply -f moodle-hpa.yaml
```

c. **Deploy Moodle using Helm:**
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install moodle bitnami/moodle \
  -f moodle-values.yaml \
  --namespace moodle \
  --create-namespace
```

---

## 6. Access Moodle

- Find the NodePort assigned to the Moodle service:
  ```bash
  kubectl get svc -n moodle
  ```
- Look for the `moodle` service and note the `NODE-PORT` (e.g., 30080).
- Get the public IP of one of your EKS worker nodes:
  ```bash
  kubectl get nodes -o wide
  ```
- Open your browser and go to:  
  `http://<NODE_PUBLIC_IP>:<NODE-PORT>`

---

## 7. (Optional) Clean Up

When finished, destroy all resources to avoid unnecessary charges:

```bash
terraform destroy -auto-approve
```

---

## Troubleshooting

- If you get permission errors, double-check your AWS Learner Lab credentials and IAM roles.
- If pods are not starting, check with:
  ```bash
  kubectl get pods -n moodle
  kubectl describe pod <pod-name> -n moodle
  ```
- For Helm issues, try `helm uninstall moodle -n moodle` and redeploy.

---

If you want to add FTP, DNS, or Directory pods, or need a report template or diagram, just let me know!


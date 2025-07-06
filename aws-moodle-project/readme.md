# 📘 AWS Moodle Project – Full Terraform & Helm Deployment

This project deploys a **fully functional Moodle LMS** on AWS using:
- **Terraform** for Infrastructure-as-Code (IaC)
- **Amazon EKS** (Kubernetes) for hosting Moodle
- **Bitnami Moodle** container deployed via **Helm**
- **Amazon RDS (Aurora MySQL)** as the Moodle backend database
- **AWS Load Balancer** for public access

---

## 🧱 Architecture Overview

- **VPC** with public/private subnets across two Availability Zones (`us-east-1a`, `us-east-1b`)
- **ALB** in public subnets for external access
- **EKS Node Groups** in private subnets (multi-AZ, auto-scaling)
- **RDS Aurora Cluster** (multi-AZ, HA) in private subnets
- **NAT Gateways** for secure outbound access
- **Security Groups** for EKS, RDS, and ALB
- **Supporting services:** S3, CloudWatch, Secrets Manager

**Text Diagram:**
```
Internet Gateway
      |
   [ALB] (Public Subnets: us-east-1a, us-east-1b)
      |
   [EKS Node Groups] (Private Subnets: us-east-1a, us-east-1b)
      |
   [RDS Aurora Cluster] (Multi-AZ)
      |
   [S3, CloudWatch, Secrets Manager]
```

**Visual Diagram:** See the included diagram in your report or `architecture.png` if provided.

---

## 🛠️ Prerequisites

| Tool        | Version         | Notes |
|-------------|-----------------|-------|
| Terraform   | >= 1.3          | Install if not present |
| AWS CLI     | Pre-installed   | In AWS CloudShell |
| Helm        | >= 3.0          | Install if not present |
| kubectl     | Pre-installed   | In AWS CloudShell |
| git         | Pre-installed   | In AWS CloudShell |

> **Tip:** In AWS CloudShell, only Terraform and Helm may need to be installed.

---

## 🏁 Step-by-Step Setup Guide

### 1. Get Your AWS Credentials
- If using AWS Learner Lab, click "Show Credentials" in your lab dashboard.
- Copy the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN`.

### 2. Configure AWS CLI
> **Note:** In AWS Learner Lab, the AWS CLI is already configured for you. You do not need to run `aws configure`.

### 3. Clone This Repository
```sh
git clone <your-repo-url>
cd aws-moodle-project
```

### 4. Install Required Tools
- **Terraform:** [Install instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl:**
  ```sh
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  kubectl version --client
  ```
- **Helm:** [Install instructions](https://helm.sh/docs/intro/install/)
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_SESSION_TOKEN=your_session_token
### 5. Initialize Terraform
```sh
terraform init
```

### 6. Set Up Pre-existing IAM Role ARNs
- Edit `terraform.tfvars` and fill in the ARNs for your pre-existing EKS cluster and node IAM roles (provided by your instructor or lab).

### 7. Deploy Infrastructure
```sh
terraform apply -auto-approve
```
- This will provision the VPC, subnets, security groups, EKS, RDS, and all supporting resources.

### 8. Update kubeconfig for EKS
```sh
aws eks update-kubeconfig --region us-east-1 --name moodle-eks-cluster
```

### 9. Check EKS Node Readiness
```sh
kubectl get nodes
```
- Wait until all nodes show `Ready`.

### 10. Deploy Moodle via Helm (if not automated)
- If your setup does not auto-deploy Moodle, run:
  ```sh
  helm upgrade --install moodle bitnami/moodle -f moodle-values.yaml
  ```

### 11. Access Moodle
- Find the ALB DNS name in the AWS Console (EC2 > Load Balancers) or from Terraform output.
- Open it in your browser.

### 12. Scale Moodle Pods (Optional)
```sh
kubectl scale deployment moodle --replicas=3
kubectl get pods
```

### 13. Cleanup
```sh
terraform destroy -auto-approve
```
- Always destroy resources when done to avoid AWS charges.

---

## 🚀 One-Line Deployment

```sh
terraform init
terraform apply -auto-approve
```

---

## 🌐 Access Moodle
- After apply, find the ALB DNS name in the AWS console (EC2 > Load Balancers) or from the Terraform output (if configured).
- Open the DNS in your browser to access Moodle.
- Login with credentials set in `moodle-values.yaml` (default: `admin`/`YourStrongMoodlePass123`).

---

## 📈 Scale Moodle Pods
- To scale up Moodle pods (e.g., to 3):
```sh
kubectl scale deployment moodle --replicas=3
```
- Check pods:
```sh
kubectl get pods
```

---

## 🛡️ Check RDS High Availability
- In AWS Console, go to RDS > Clusters > moodle-aurora-cluster.
- Confirm there are 2 instances (Writer/Reader or Multi-AZ).

---

## 🧹 Cleanup (Destroy All Resources)
To avoid AWS charges, destroy all resources when done:
```sh
terraform destroy
```
- Type `yes` when prompted.

---

## 🎬 Demo Checklist
- [ ] Show VPC, subnets, and security groups in AWS Console
- [ ] Show EKS cluster and node group
- [ ] Show RDS cluster with 2 instances (HA)
- [ ] Show ALB and access Moodle in browser
- [ ] Show scaling Moodle pods (multiple pods running)
- [ ] Show ConfigMap/Helm values in use
- [ ] Show one-line deployment (terraform apply)

---

## 📝 Notes for AWS Learner Lab
- IAM roles for EKS are auto-detected using Terraform data sources.
- You cannot create or edit IAM roles in Learner Lab; use the pre-existing roles.
- Always destroy resources after use to avoid quota issues for your classmates.

---

## 🔑 AWS Credentials Setup

If you are using AWS Learner Lab, your credentials are provided in the lab dashboard. You can copy and paste them into your terminal as environment variables, or add them to your AWS credentials file.

### Option 1: Set as Environment Variables (Recommended for Learner Lab)
```sh
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_SESSION_TOKEN=your_session_token
```
- Replace the values above with those from your Learner Lab dashboard (see the 'AWS CLI' section).
- Run these commands in your terminal **before running any Terraform or AWS CLI commands**.

### Option 2: Add to `~/.aws/credentials`
Paste the following into `~/.aws/credentials` (create the file if it doesn't exist):
```ini
[default]
aws_access_key_id=your_access_key_id
aws_secret_access_key=your_secret_access_key
aws_session_token=your_session_token
```
- Replace the values with those from your Learner Lab dashboard.

> **Note:** In AWS Learner Lab, environment variables are usually set for you, but you may need to refresh them if your session expires.

---

## 🛠️ Troubleshooting: DB Subnet Group Already Exists

**Error:**
```
Error: DBSubnetGroupAlreadyExists: DB Subnet Group 'moodle-db-subnet-group' already exists
```

**How to Fix:**
1. Go to the AWS Console → RDS → Subnet Groups.
2. Find and delete the subnet group named `moodle-db-subnet-group`.
3. Re-run your Terraform command (`terraform apply` or `terraform destroy`).

This error happens if a previous deployment was only partially destroyed or if the subnet group was created manually. Cleaning it up in the AWS Console resolves the issue.

---

## 🛠️ Troubleshooting: Moodle Helm Release Fails (Pods Pending, PVC, or StorageClass Errors)

If you see errors like:
- `pod has unbound immediate PersistentVolumeClaims`
- `storageclass.storage.k8s.io "gp3" not found`
- Moodle pods stuck in `Pending` state

**This means your EKS cluster does not have the required 'gp3' StorageClass for AWS EBS volumes.**

### How to Fix

1. **Create the 'gp3' StorageClass:**
   Run this command in your terminal:
   ```sh
   kubectl apply -f - <<EOF
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: gp3
   provisioner: kubernetes.io/aws-ebs
   parameters:
     type: gp3
   reclaimPolicy: Delete
   volumeBindingMode: WaitForFirstConsumer
   allowVolumeExpansion: true
   EOF
   ```

2. **Delete stuck Moodle pods and PVCs (optional, but recommended):**
   ```sh
   kubectl delete pod -l app.kubernetes.io/name=moodle
   kubectl delete pvc -l app.kubernetes.io/name=moodle
   ```

3. **Re-run your deployment:**
   ```sh
   terraform apply -auto-approve
   ```
   or, if using Helm directly:
   ```sh
   helm upgrade --install moodle bitnami/moodle --namespace default
   ```

---

**If you see any other errors, check pod and event status:**
```sh
kubectl get pods -A
kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```

Copy any error messages here for further help!

---

## Troubleshooting & Recovery Workflow

### Common Errors & Solutions

#### 1. EKS Node Group: KeyPair Not Found
- **Error:** `KeyPair eks-key not found`
- **Solution:**
  - This project now uses Terraform to generate and manage the key pair automatically. No manual action is needed.

#### 2. Kubernetes ConfigMap/Helm Release: Unauthorized
- **Error:** `Unauthorized` or `the server has asked for the client to provide credentials`
- **Solution:**
  - This means your IAM role is not mapped as an admin in the EKS cluster. This can happen if the cluster was created by a different user/session.
  - **Fix:** Destroy and re-create the EKS cluster as your current user/role.

#### 3. kubectl Not Installed
- **Error:** `kubectl: command not found`
- **Solution:**
  - Install kubectl using:
    ```sh
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    kubectl version --client
    ```

#### 4. "You must be logged in to the server"
- **Error:** `You must be logged in to the server (the server has asked for the client to provide credentials)`
- **Solution:**
  - Ensure you are using the same AWS user/role as the one that created the cluster.
  - If not, destroy and re-create the cluster as your current user/role.

---

### Step-by-Step Recovery Workflow

1. **Destroy all resources to reset IAM mapping:**
   ```sh
   terraform destroy -auto-approve
   ```
2. **Re-create all resources:**
   ```sh
   terraform apply -auto-approve
   ```
3. **Update your kubeconfig for EKS access:**
   ```sh
   aws eks update-kubeconfig --region us-east-1 --name moodle-eks-cluster
   ```
4. **Check EKS node readiness:**
   ```sh
   kubectl get nodes
   ```
   - If you see nodes in `Ready` state, proceed.
   - If you still get a credentials error, ensure you are using the correct AWS user/role.
5. **Re-run Terraform to deploy Kubernetes resources:**
   ```sh
   terraform apply -auto-approve
   ```

---

If you encounter any other errors, copy the error message and seek help with your current AWS user/role and error details. 

## Persistent Storage in AWS Learner Lab (Static EBS Provisioning)

**IMPORTANT:** Due to IAM restrictions in AWS Learner Lab, dynamic EBS provisioning (via the EBS CSI driver) is NOT possible. You must use a statically provisioned EBS volume for Moodle persistent storage.

### Why?
- The EKS node IAM role cannot be modified to allow dynamic EBS volume creation.
- This is a limitation of the Learner Lab environment (see aws_learner_lab_readme.txt).

### Steps to Use Static EBS for Moodle

1. **Create an EBS Volume**
   - Go to the AWS Console → EC2 → Volumes → Create Volume.
   - Type: gp2 or gp3, Size: 8 GiB (or as needed), Availability Zone: (must match your EKS node AZ, e.g., us-east-1a).
   - Note the Volume ID (e.g., vol-xxxxxxxx).

2. **Attach the EBS Volume to the correct AZ**
   - Ensure the volume is in the same AZ as your EKS node(s). You can check node AZs with:
     ```sh
     kubectl get nodes -o wide
     ```

3. **Create a PersistentVolume (PV) and PersistentVolumeClaim (PVC)**
   - Save the following as `static-pv.yaml` and apply it:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: moodle-static-pv
spec:
  capacity:
    storage: 8Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  csi:
    driver: kubernetes.io/aws-ebs
    volumeHandle: <your-volume-id>  # e.g., vol-xxxxxxxx
    fsType: ext4
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: topology.kubernetes.io/zone
              operator: In
              values:
                - <your-az>  # e.g., us-east-1a
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moodle-static-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 8Gi
  volumeName: moodle-static-pv
```

- Replace `<your-volume-id>` and `<your-az>` with your actual values.
- Apply with:
  ```sh
  kubectl apply -f static-pv.yaml
  ```

4. **Configure Moodle Helm Chart to Use the Static PVC**
   - The `moodle-values.yaml` is already set to use `existingClaim: moodle-static-pv-claim`.

5. **Install/Upgrade Moodle**
   ```sh
   helm upgrade --install moodle bitnami/moodle -f moodle-values.yaml
   ```

### Notes
- The PV reclaim policy is set to `Retain` to prevent accidental data loss.
- You must manually delete the EBS volume if you no longer need it.
- This approach is required due to Learner Lab IAM restrictions.

--- 
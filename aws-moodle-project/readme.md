# 📘 AWS Moodle Project – Docker & EC2 Deployment

This project deploys a **fully functional Moodle LMS** on AWS using:
- **Terraform** for Infrastructure-as-Code (IaC)
- **Amazon EC2** for hosting Moodle (with Docker)
- **Bitnami Moodle Docker image**
- **Amazon RDS (Aurora MySQL)** as the Moodle backend database
- **Amazon ALB** for public access

---

## 🧱 Architecture Overview

- **VPC** with public/private subnets across two Availability Zones (`us-east-1a`, `us-east-1b`)
- **ALB** in public subnets for external access
- **EC2 Instance(s)** in public subnets (auto scaling possible)
- **RDS Aurora Cluster** (multi-AZ, HA) in private subnets
- **Security Groups** for EC2, RDS, and ALB

---

## 🛠️ Prerequisites

| Tool        | Version         | Notes |
|-------------|-----------------|-------|
| Terraform   | >= 1.3          | Install if not present |
| AWS CLI     | Pre-installed   | In AWS CloudShell |
| Docker      | >= 20           | On EC2 instance |
| git         | Pre-installed   | In AWS CloudShell |

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

### 4. Initialize Terraform
```sh
terraform init
```

### 5. Deploy Infrastructure
```sh
terraform apply -auto-approve
```
- This will provision the VPC, subnets, security groups, EC2, RDS, and ALB.

### 6. Connect to Your EC2 Instance
- Find the public IP of your EC2 instance in the AWS Console or Terraform output.
- SSH into the instance:
```sh
ssh -i ~/.ssh/labsuser.pem ubuntu@<ec2-public-ip>
```

### 7. Install Docker (if not already installed)
```sh
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker ubuntu
newgrp docker
```

### 8. Deploy Moodle with Docker (Bitnami)

#### Option 1: Using Docker Compose (Recommended)
Create a `docker-compose.yml` file:
```yaml
version: '2'
services:
  moodle:
    image: bitnami/moodle:latest
    ports:
      - '8080:8080'
      - '8443:8443'
    environment:
      - MOODLE_DATABASE_HOST=<your-rds-endpoint>
      - MOODLE_DATABASE_PORT_NUMBER=3306
      - MOODLE_DATABASE_USER=<your-db-username>
      - MOODLE_DATABASE_NAME=<your-db-name>
      - MOODLE_DATABASE_PASSWORD=<your-db-password>
```
Run:
```sh
docker-compose up -d
```

#### Option 2: Run Directly with Docker
```sh
docker run -d --name moodle \
  -p 8080:8080 -p 8443:8443 \
  -e MOODLE_DATABASE_HOST=<your-rds-endpoint> \
  -e MOODLE_DATABASE_PORT_NUMBER=3306 \
  -e MOODLE_DATABASE_USER=<your-db-username> \
  -e MOODLE_DATABASE_NAME=<your-db-name> \
  -e MOODLE_DATABASE_PASSWORD=<your-db-password> \
  bitnami/moodle:latest
```

- Access Moodle at `http://<alb-dns-name>:8080` (find ALB DNS in AWS Console or Terraform output).

---

## 🌐 Access Moodle
- After apply, find the ALB DNS name in the AWS console (EC2 > Load Balancers) or from the Terraform output.
- Open the DNS in your browser to access Moodle.
- Login with credentials set during the Moodle setup process.

---

## 📈 Scale Moodle Web Servers
- To scale, you can update your Terraform to use an Auto Scaling Group for EC2, or manually launch more EC2 instances and register them with the ALB.

---

## 🧹 Cleanup (Destroy All Resources)
To avoid AWS charges, destroy all resources when done:
```sh
terraform destroy
```
- Type `yes` when prompted.

---

## 📦 Reference: Bitnami Moodle Docker
- [Bitnami Moodle Docker GitHub](https://github.com/bitnami/containers/tree/main/bitnami/moodle)
- [Bitnami Docker Compose Examples](https://github.com/bitnami/containers/tree/main/bitnami/moodle#using-docker-compose)

---

## 📝 Notes
- This setup does not use Kubernetes/EKS. For K8s deployment, see Bitnami's Helm chart or EKS documentation.
- For horizontal scaling, use an Auto Scaling Group and ensure all EC2s use the same RDS backend.

---

## 🎬 Demo Checklist
- [ ] Show VPC, subnets, and security groups in AWS Console
- [ ] Show EC2 instances and ALB
- [ ] Show RDS cluster with 2 instances (HA)
- [ ] Show access Moodle in browser
- [ ] Show scaling Moodle web servers (multiple instances running)
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
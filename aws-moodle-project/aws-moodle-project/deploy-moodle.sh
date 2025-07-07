#!/bin/bash

# Set these variables before running!
EKS_CLUSTER_NAME="your-eks-cluster-name"
AWS_REGION="us-east-1"
MOODLE_DB_HOST="your-aurora-endpoint"
MOODLE_DB_USER="root"
MOODLE_DB_PASSWORD="your-db-password"
MOODLE_DB_NAME="moodledb"

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Add Bitnami repo and update
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy Moodle with Helm
helm install moodle bitnami/moodle \
  --set externalDatabase.host=$MOODLE_DB_HOST \
  --set externalDatabase.user=$MOODLE_DB_USER \
  --set externalDatabase.password=$MOODLE_DB_PASSWORD \
  --set externalDatabase.database=$MOODLE_DB_NAME \
  --set service.type=LoadBalancer \
  --set replicaCount=2

# Wait and get the service URL
echo "Waiting for Moodle service external IP..."
sleep 30
kubectl get svc

echo "Done! Check the EXTERNAL-IP above to access Moodle."
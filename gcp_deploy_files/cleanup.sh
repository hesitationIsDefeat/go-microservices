#!/bin/bash
# cleanup.sh
# Removes all project resources from GCP

PROJECT_ID=$(gcloud config get-value project)
ZONE="europe-west1-b"
REGION="europe-west1"

echo "Starting Cleanup for project $PROJECT_ID..."

# 1. GKE Cluster
echo "Deleting GKE Cluster..."
gcloud container clusters delete go-microservices-cluster --zone=$ZONE --quiet || echo "Cluster not found or already deleted."

# 2. Compute VM
echo "Deleting Mongo VM..."
gcloud compute instances delete mongo-vm --zone=$ZONE --quiet || echo "VM not found or already deleted."

# 3. Cloud SQL
echo "Deleting Cloud SQL Instance..."
gcloud sql instances delete postgres-db --quiet || echo "SQL Instance not found or already deleted."

# 4. Cloud Function
echo "Deleting Cloud Function..."
gcloud functions delete mail-function --region=$REGION --quiet || echo "Function not found or already deleted."

echo "Cleanup Complete."

#!/bin/bash
# deploy_cloud_sql.sh
# Deploys a Cloud SQL instance for Postgres

PROJECT_ID=$(gcloud config get-value project)
REGION="europe-west1"
INSTANCE_NAME="postgres-db"

# Enable Service Networking for Private IP (Simplified for this script, assumes default network)
# If this fails, user might need to configure VPC peering manually.

echo "Creating Cloud SQL Instance (this may take 10-15 minutes)..."
gcloud sql instances create $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --database-version=POSTGRES_14 \
    --tier=db-f1-micro \
    --region=$REGION \
    --root-password=password

echo "Creating 'users' database..."
gcloud sql databases create users --instance=$INSTANCE_NAME

echo "Creating 'postgres' user..."
# Default 'postgres' user exists, we just set password if needed, or create a 'postgres' service user
gcloud sql users set-password postgres --instance=$INSTANCE_NAME --password=password

echo "Cloud SQL Instance Ready. Connection Name:"
gcloud sql instances describe $INSTANCE_NAME --format="value(connectionName)"

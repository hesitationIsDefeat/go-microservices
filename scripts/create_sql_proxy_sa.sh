#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
SA_NAME="sql-proxy"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo "====================================="
echo " Setting up Service Account for Proxy"
echo "====================================="

if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "ℹ️  Service Account '$SA_NAME' already exists. Skipping creation."
else
    echo "--- Creating Service Account ---"
    gcloud iam service-accounts create $SA_NAME \
        --display-name="Cloud SQL Proxy Service Account" \
        --project=$PROJECT_ID
    echo "✔ Created."
fi

echo "--- Ensuring IAM Roles ---"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/cloudsql.client" \
    --condition=None \
    --quiet >/dev/null

if [ -f "key.json" ]; then
    echo "ℹ️  File 'key.json' already exists. Skipping key generation."
else
    echo "--- Generating key.json ---"
    gcloud iam service-accounts keys create key.json \
        --iam-account=$SA_EMAIL \
        --project=$PROJECT_ID
    echo "✔ Key generated."
fi

echo ""
echo "==========================================="
echo " Service Account Setup COMPLETE ✔"
echo "==========================================="
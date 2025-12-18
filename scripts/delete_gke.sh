#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="gcp-cluster" 
ZONE="europe-west1-d"

STATIC_IP_NAME="broker-ip"

echo "========================================"
echo " GKE Cleanup Script"
echo "========================================"

echo "--- Checking for GKE Cluster: $CLUSTER_NAME ---"

if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "Found cluster '$CLUSTER_NAME'. Deleting... (This takes 5-10 minutes)"
    
    gcloud container clusters delete "$CLUSTER_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --quiet
        
    echo "✔ Cluster deleted."
else
    echo "ℹ️  Cluster '$CLUSTER_NAME' not found (in zone $ZONE). Skipping."
fi

echo ""
echo "--- Checking for Static IP: $STATIC_IP_NAME ---"

if gcloud compute addresses describe "$STATIC_IP_NAME" --global --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "Found IP '$STATIC_IP_NAME'. Deleting..."
    
    gcloud compute addresses delete "$STATIC_IP_NAME" \
        --global \
        --project="$PROJECT_ID" \
        --quiet
        
    echo "✔ Static IP deleted."
else
    echo "ℹ️  Static IP '$STATIC_IP_NAME' not found. Skipping."
fi

echo ""
echo "========================================"
echo " GKE & Networking Cleanup COMPLETE"
echo "========================================"
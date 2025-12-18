#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
INGRESS_NAME="broker-ingress"
STATIC_IP_NAME="broker-ip"

echo "========================================"
echo " Deleting Ingress & Load Balancer"
echo "========================================"

echo "--- Deleting Kubernetes Ingress: $INGRESS_NAME ---"
kubectl delete ingress "$INGRESS_NAME" --ignore-not-found=true

echo "✔ Ingress deleted. (The GCP Load Balancer will spin down in a few minutes)"

echo ""
echo "--- Checking for Reserved Static IP: $STATIC_IP_NAME ---"

if gcloud compute addresses describe "$STATIC_IP_NAME" --global --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "Found IP '$STATIC_IP_NAME'. Deleting..."
    gcloud compute addresses delete "$STATIC_IP_NAME" --global --project="$PROJECT_ID" --quiet
    echo "✔ Static IP deleted."
else
    echo "ℹ️  Static IP '$STATIC_IP_NAME' not found. Skipping."
fi

echo ""
echo "========================================"
echo " Ingress Cleanup COMPLETE"
echo "========================================"
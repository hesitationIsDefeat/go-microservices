#!/bin/bash
set -e

INSTANCE_NAME="postgres-instance"
PROJECT_ID=$(gcloud config get-value project)

echo "================================"
echo " Checking for Cloud SQL (Postgres)"
echo "================================"

if gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID >/dev/null 2>&1; then
  echo "Found instance '$INSTANCE_NAME'. Proceeding with deletion..."

  echo "--- Disabling deletion protection ---"
  gcloud sql instances patch $INSTANCE_NAME --project=$PROJECT_ID --no-deletion-protection --quiet

  echo "--- Deleting instance ---"
  gcloud sql instances delete $INSTANCE_NAME --project=$PROJECT_ID --quiet

  echo ""
  echo "======================================"
  echo " ✅ Cloud SQL Postgres DELETED SUCCESSFULLY"
  echo "======================================"
else
  echo "⚠️ Instance '$INSTANCE_NAME' does not exist. Skipping delete."
fi
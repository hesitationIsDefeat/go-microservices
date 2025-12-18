#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
SA_NAME="sql-proxy"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo "====================================="
echo " Deleting Service Account & Key"
echo "====================================="

echo "--- Removing IAM Role ---"
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/cloudsql.client" \
    --condition=None \
    --quiet >/dev/null 2>&1 || true
echo "✔ Role binding removed (if it existed)."

if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "--- Deleting Service Account '$SA_NAME' ---"
    gcloud iam service-accounts delete "$SA_EMAIL" --project="$PROJECT_ID" --quiet
    echo "✔ Service Account deleted."
else
    echo "ℹ️  Service Account '$SA_NAME' does not exist. Skipping."
fi

if [ -f "key.json" ]; then
    echo "--- Removing local key.json ---"
    rm key.json
    echo "✔ key.json removed."
else
    echo "ℹ️  Local file 'key.json' not found. Skipping."
fi

echo ""
echo "==========================================="
echo " Cleanup COMPLETE ✔"
echo "==========================================="
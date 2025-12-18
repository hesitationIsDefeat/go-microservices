#!/bin/bash
set -e

echo ""
echo "--- 1. Checking Project Selection ---"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "(unset)" ]; then
    echo "❌ No active project found."
    echo "Please set your project ID and run this script again:"
    echo "   gcloud config set project [YOUR_PROJECT_ID]"
    exit 1
else
    echo "✔ Active Project: $PROJECT_ID"
fi

echo ""
echo "--- 2. Verifying User Login ---"
ACCOUNT=$(gcloud config get-value account 2>/dev/null)

if [ -z "$ACCOUNT" ] || [ "$ACCOUNT" == "(unset)" ]; then
    echo "⚠️  Not logged in."
    echo "🔄 Opening browser for login..."
    gcloud auth login
    echo "✔ Login complete."
else
    echo "✔ Already logged in as: $ACCOUNT"
fi

echo ""
echo "--- 3. Setting Application Default Credentials ---"
if [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    echo "🔄 Generating ADC JSON file..."
    gcloud auth application-default login
else
    echo "✔ ADC is already configured."
fi

echo ""
echo "--- 4. Configuring Docker Auth for GCR ---"
gcloud auth configure-docker --quiet
echo "✔ Docker configured to use gcloud credentials."

echo ""
echo "--- 5. Enabling Required APIs ---"

APIS=(
    "compute.googleapis.com"          # VMs, Load Balancers, Firewall rules
    "container.googleapis.com"        # Kubernetes Engine (GKE)
    "sqladmin.googleapis.com"         # Cloud SQL
    "pubsub.googleapis.com"           # Cloud Pub/Sub
    "cloudfunctions.googleapis.com"   # Cloud Functions
    "run.googleapis.com"              # Cloud Run (Required for Gen 2 Functions)
    "cloudbuild.googleapis.com"       # Required to build Cloud Functions
    "artifactregistry.googleapis.com" # Required for container storage
    "iam.googleapis.com"              # Identity & Access Management
    "servicenetworking.googleapis.com" # Needed for Private IP SQL (if used)
)

gcloud services enable "${APIS[@]}" --project="$PROJECT_ID"

echo "✔ All APIs enabled successfully."

echo ""
echo "==================================================="
echo " AUTHENTICATION SETUP COMPLETE ✔"
echo "==================================================="
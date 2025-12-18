#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
ZONE="europe-west1-d"
CLUSTER_NAME="gcp-cluster"

TARGET_MACHINE_TYPE="e2-medium"
NUM_STARTING_NODES=1
NUM_MIN_NODES=1
NUM_MAX_NODES=3

NEW_POOL_NAME="pool-${TARGET_MACHINE_TYPE}"

echo "========================================"
echo " Setting up GKE Cluster: $CLUSTER_NAME"
echo "========================================"

echo "--- Checking for existing cluster '$CLUSTER_NAME' ---"
if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "⚠️  Cluster '$CLUSTER_NAME' already exists. Deleting it for a fresh install..."
    
    gcloud container clusters delete "$CLUSTER_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --quiet
        
    echo "✔ Cluster deleted."
fi

echo "--- Creating Cluster (Control Plane & Nodes) ---"
gcloud container clusters create "$CLUSTER_NAME" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --num-nodes=1 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3 \
    --machine-type="e2-medium" \
    --disk-size=30GB \
    --release-channel=regular \
    --scopes=cloud-platform \
    --quiet

echo "✔ Cluster created successfully."

echo "--- Configuring kubectl ---"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE" --project="$PROJECT_ID"

echo "--- Checking Node Pool Machine Types ---"

POOLS=$(gcloud container node-pools list --cluster="$CLUSTER_NAME" --zone="$ZONE" --format="value(name)")

if echo "$POOLS" | grep -q "$NEW_POOL_NAME"; then
    echo "ℹ️  Target pool '$NEW_POOL_NAME' already exists. No upgrade needed."
else
    echo "⚠️  Target pool '$NEW_POOL_NAME' not found. Checking for legacy pools..."
    
    if gcloud container node-pools describe default-pool --cluster="$CLUSTER_NAME" --zone="$ZONE" >/dev/null 2>&1; then
        CURRENT_TYPE=$(gcloud container node-pools describe default-pool --cluster="$CLUSTER_NAME" --zone="$ZONE" --format="value(config.machineType)")
        
        if [ "$CURRENT_TYPE" != "$TARGET_MACHINE_TYPE" ]; then
            echo "🔄 UPGRADE REQUIRED: Current pool is $CURRENT_TYPE, Target is $TARGET_MACHINE_TYPE."
            
            echo "--- Creating New Node Pool: $NEW_POOL_NAME ---"
            gcloud container node-pools create "$NEW_POOL_NAME" \
                --cluster="$CLUSTER_NAME" \
                --zone="$ZONE" \
                --machine-type="$TARGET_MACHINE_TYPE" \
                --num-nodes="$NUM_NODES" \
                --scopes=cloud-platform \
                --quiet
            
            echo "--- Deleting Old Pool (Migrating Workloads) ---"
            gcloud container node-pools delete default-pool \
                --cluster="$CLUSTER_NAME" \
                --zone="$ZONE" \
                --quiet
                
            echo "✔ Upgrade Complete. Workloads migrated to $TARGET_MACHINE_TYPE."
        else
            echo "ℹ️  'default-pool' is already $TARGET_MACHINE_TYPE. No action needed."
        fi
    fi
fi

echo "--- Uploading Cloud SQL Secret ---"
if kubectl get secret cloud-sql-creds >/dev/null 2>&1; then
    echo "ℹ️  Secret 'cloud-sql-creds' already exists."
elif [ -f "key.json" ]; then
    kubectl create secret generic cloud-sql-creds --from-file=key.json=./key.json
    echo "✔ Secret 'cloud-sql-creds' created."
else
    echo "⚠️  WARNING: 'key.json' not found! Auth service will fail."
fi

echo ""
echo "========================================"
echo " GKE Setup & Upgrade COMPLETE ✔"
echo "========================================"
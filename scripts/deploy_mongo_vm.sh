#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION="europe-west1" 
ZONE="europe-west1-d"
VM_NAME="mongo-vm"
DISK_NAME="mongo-disk"
DISK_SIZE="20GB"
STARTUP_SCRIPT="./mongo_startup.sh"
IP_NAME="mongo-static-ip"
YAML_PATH="../gke/logger.yaml" 

echo "========================================"
echo " Setting up MongoDB VM with Static IP"
echo "========================================"

if [ ! -f "$STARTUP_SCRIPT" ]; then
    echo "❌ Error: Startup script '$STARTUP_SCRIPT' not found."
    exit 1
fi
if [ ! -f "$YAML_PATH" ]; then
    echo "❌ Error: YAML file '$YAML_PATH' not found. Check the path."
    exit 1
fi

echo "--- Checking Static IP: $IP_NAME ---"
if gcloud compute addresses describe "$IP_NAME" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "ℹ️  IP '$IP_NAME' already reserved."
else
    echo "Creating static internal IP..."
    gcloud compute addresses create "$IP_NAME" \
        --region="$REGION" \
        --subnet="default" \
        --project="$PROJECT_ID" \
        --quiet
    echo "✔ IP Reserved."
fi

MONGO_IP=$(gcloud compute addresses describe "$IP_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(address)")
echo "📌 Static IP Address is: $MONGO_IP"


echo "--- Checking Persistent Disk '$DISK_NAME' ---"
if gcloud compute disks describe "$DISK_NAME" --zone="$ZONE" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "ℹ️  Disk '$DISK_NAME' already exists. Skipping creation."
else
    echo "Creating persistent disk..."
    gcloud compute disks create "$DISK_NAME" \
        --project="$PROJECT_ID" \
        --size="$DISK_SIZE" \
        --zone="$ZONE" \
        --quiet
    echo "✔ Disk created."
fi

echo "--- Checking VM Instance '$VM_NAME' ---"
if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "ℹ️  VM '$VM_NAME' already exists. Skipping creation."
else
    echo "Creating VM instance with Static IP $MONGO_IP ..."
    gcloud compute instances create "$VM_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE" \
        --machine-type=e2-small \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --private-network-ip="$MONGO_IP" \
        --tags=mongo-server \
        --metadata=MONGO_USER=admin,MONGO_PASS=password \
        --metadata-from-file startup-script="$STARTUP_SCRIPT" \
        --disk=name="$DISK_NAME",device-name="$DISK_NAME",mode=rw,boot=no,auto-delete=no \
        --quiet
    echo "✔ VM created."
fi

echo "--- Checking Firewall Rule 'allow-mongo-internal' ---"
if gcloud compute firewall-rules describe allow-mongo-internal --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "ℹ️  Firewall rule 'allow-mongo-internal' already exists. Skipping."
else
    echo "Creating Firewall rule..."
    gcloud compute firewall-rules create allow-mongo-internal \
        --project="$PROJECT_ID" \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:27017 \
        --source-ranges=10.0.0.0/8 \
        --target-tags=mongo-server \
        --quiet
    echo "✔ Firewall rule created."
fi

echo "--- Updating $YAML_PATH with Static IP ---"

NEW_CONNECTION_STRING="mongodb://admin:password@$MONGO_IP:27017"

if grep -q "MONGO_URL_PLACEHOLDER" "$YAML_PATH"; then
    sed -i.bak "s|MONGO_URL_PLACEHOLDER|$NEW_CONNECTION_STRING|g" "$YAML_PATH"
    
    echo "✔ Successfully updated $YAML_PATH"
    echo "  Old: MONGO_URL_PLACEHOLDER"
    echo "  New: $NEW_CONNECTION_STRING"
    
    rm "$YAML_PATH.bak"
else
    echo "⚠️  WARNING: Placeholder 'MONGO_URL_PLACEHOLDER' not found in $YAML_PATH."
    echo "   Could not inject IP address automatically."
fi


echo ""
echo "========================================"
echo " MongoDB VM Deployment COMPLETE ✔"
echo " Logger YAML Updated with Static IP."
echo "========================================"
echo "Static Internal IP Address: $MONGO_IP"
echo "Next Step: Run your GKE deployment for logger-service."
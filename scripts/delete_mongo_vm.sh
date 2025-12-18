#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)
REGION="europe-west1"
ZONE="europe-west1-d"
VM_NAME="mongo-vm"
DISK_NAME="mongo-disk"
FIREWALL_RULE="allow-mongo-internal"
IP_NAME="mongo-static-ip"

YAML_DIR="../gke"
TARGET_FILE="logger.yaml"   
SOURCE_FILE="logger-original.yaml"    

echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Zone: $ZONE"
echo "VM Name: $VM_NAME"
echo "Disk Name: $DISK_NAME"
echo "Firewall Rule: $FIREWALL_RULE"
echo "Static IP Name: $IP_NAME"
echo ""

echo "--- Deleting VM instance $VM_NAME ---"
gcloud compute instances delete $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet || echo "VM not found or already deleted."

echo ""

echo "--- Deleting disk $DISK_NAME ---"
gcloud compute disks delete $DISK_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet || echo "Disk not found or already deleted."

echo ""

echo "--- Deleting firewall rule $FIREWALL_RULE ---"
gcloud compute firewall-rules delete $FIREWALL_RULE \
  --project=$PROJECT_ID \
  --quiet || echo "Firewall rule not found or already deleted."

echo ""

echo "--- Deleting Static IP $IP_NAME ---"
gcloud compute addresses delete $IP_NAME \
  --project=$PROJECT_ID \
  --region=$REGION \
  --quiet || echo "Static IP not found or already deleted."

echo ""

echo "--- Resetting $TARGET_FILE configuration ---"
if [ -f "$YAML_DIR/$SOURCE_FILE" ]; then
    cp "$YAML_DIR/$SOURCE_FILE" "$YAML_DIR/$TARGET_FILE"
    echo "✔ Successfully copied $SOURCE_FILE to $TARGET_FILE."
    echo "  $TARGET_FILE has been reset to use placeholders."
else
    echo "⚠️  WARNING: Could not find '$YAML_DIR/$SOURCE_FILE'."
    echo "   Skipping reset. Please manually revert the IP address in $TARGET_FILE."
fi

echo ""
echo "Cleanup complete."
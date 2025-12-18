#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)

echo "==================================================="
echo " 💰 PRICING AUDIT FOR PROJECT: $PROJECT_ID"
echo "==================================================="
echo "Run this script, then enter these values into:"
echo "https://cloud.google.com/products/calculator"
echo "==================================================="

echo ""
echo "--- 1. GKE CLUSTER (Enter under 'Kubernetes Engine' or 'Compute Engine') ---"
gcloud container clusters list \
    --format="table[box](name, location, nodePools[].config.machineType, currentNodeCount, status)"

echo ""
echo "--- 2. CLOUD SQL (Enter under 'Cloud SQL for PostgreSQL') ---"
gcloud sql instances list \
    --format="table[box](name, region, settings.tier, settings.dataDiskSizeGb, settings.availabilityType, state)"

echo ""
echo "--- 3. MONGODB VM (Enter under 'Compute Engine') ---"
gcloud compute instances list \
    --filter="name:mongo-vm" \
    --format="table[box](name, zone, machineType, status)"

echo ""
echo "--- 4. CLOUD FUNCTIONS (Enter under 'Cloud Functions') ---"
gcloud functions list \
    --format="table[box](name, environment, serviceConfig.availableMemory, serviceConfig.availableCpu, serviceConfig.minInstanceCount, serviceConfig.maxInstanceCount)"

echo ""
echo "--- 5. STORAGE / DISKS (Enter under 'Persistent Disk') ---"
echo "Standard/Balanced Disks (Total GB):"
gcloud compute disks list --filter="type~'pd-standard|pd-balanced'" --format="value(sizeGb)" | awk '{s+=$1} END {print s}'
echo "SSD Disks (Total GB):"
gcloud compute disks list --filter="type='pd-ssd'" --format="value(sizeGb)" | awk '{s+=$1} END {print s}'

echo ""
echo "--- 6. NETWORKING (Enter under 'Cloud Load Balancing') ---"
LB_COUNT=$(gcloud compute forwarding-rules list --format="value(name)" | wc -l)
echo "Active Load Balancers (Forwarding Rules): $LB_COUNT"

echo ""
echo "--- 7. PUBSUB (Enter under 'Cloud Pub/Sub') ---"
TOPIC_COUNT=$(gcloud pubsub topics list --format="value(name)" | wc -l)
echo "Active Topics: $TOPIC_COUNT"
echo "(Note: Pub/Sub is charged by Data Volume (GB), usually free for low traffic)"

echo ""
echo "==================================================="
echo " AUDIT COMPLETE"
echo "==================================================="
#!/bin/bash

# Instructions for setting up a legacy VM on Google Compute Engine

PROJECT_ID="cmpebounproject"
ZONE="europe-west1-b"
VM_NAME="legacy-vm"

echo "Creating VM instance..."
gcloud compute instances create $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server

echo "Allowing HTTP traffic..."
gcloud compute firewall-rules create allow-http-vm \
    --project=$PROJECT_ID \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

echo "VM created. You can SSH into it using:"
echo "gcloud compute ssh $VM_NAME --project=$PROJECT_ID --zone=$ZONE"

echo "To run the background log processor, copy the script 'log_processor.sh' to the VM and run it."

# deploy_mongo_vm.ps1
# Deploys a VM with MongoDB for the CMPE 48A Project

$PROJECT_ID = gcloud config get-value project
$ZONE = "europe-west1-b"
$VM_NAME = "mongo-vm"

# 1. Create the VM
Write-Host "Creating VM instance $VM_NAME..."
gcloud compute instances create $VM_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --machine-type=e2-small `
    --image-family=cos-stable `
    --image-project=cos-cloud `
    --tags=mongo-server `
    --metadata=startup-script="#! /bin/bash
docker run -d -p 27017:27017 `
    -e MONGO_INITDB_DATABASE=logs `
    -e MONGO_INITDB_ROOT_USERNAME=admin `
    -e MONGO_INITDB_ROOT_PASSWORD=password `
    -v /var/lib/mongo:/data/db `
    --name mongodb `
    --restart=always `
    mongo:4.2.17-bionic"

# 2. Configure Firewall
Write-Host "Creating Firewall rule for MongoDB..."
gcloud compute firewall-rules create allow-mongo-internal `
    --project=$PROJECT_ID `
    --direction=INGRESS `
    --priority=1000 `
    --network=default `
    --action=ALLOW `
    --rules=tcp:27017 `
    --source-ranges=10.0.0.0/8 `
    --target-tags=mongo-server

Write-Host "MongoDB VM Deployed."

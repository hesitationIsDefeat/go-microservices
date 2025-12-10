# GCP Resume Script
# Wakes up the environment.
# 1. Starts Legacy VM
# 2. Resizes GKE Cluster to 3 nodes
# 3. Re-applies Load Balancers

$ClusterName = "go-microservices-cluster"
$Zone = "europe-west1-b"
$VmName = "mongo-vm"
$SqlName = "postgres-db"

Write-Host "=================================================="
Write-Host "Resuming GCP Environment..."
Write-Host "=================================================="

# 1. Start VM
Write-Host "1. Starting Mongo VM..."
gcloud compute instances start $VmName --zone=$Zone --quiet
Write-Host "   VM started." -ForegroundColor Green

# 2. Start Cloud SQL
Write-Host "2. Starting Cloud SQL..."
gcloud sql instances patch $SqlName --activation-policy=ALWAYS --quiet
Write-Host "   Cloud SQL Started." -ForegroundColor Green

# 3. Resize GKE Cluster
Write-Host "3. Resizing GKE Cluster to 1 node..."
gcloud container clusters resize $ClusterName --num-nodes=1 --zone=$Zone --quiet
Write-Host "   Cluster resized to 1." -ForegroundColor Green

# 4. Re-apply Load Balancers
Write-Host "4. Re-applying Load Balancer Services..."
kubectl apply -f k8s/broker-service.yaml
kubectl apply -f k8s/front-end-service.yaml

Write-Host "   Waiting for External IPs (this may take a minute)..."
Start-Sleep -Seconds 10
kubectl get svc broker-service front-end-service

Write-Host "=================================================="
Write-Host "Environment Resumed."
Write-Host "IMPORTANT: You have NEW External IPs."
Write-Host "Update your 'front-end-deployment.yaml' with the new Broker IP,"
Write-Host "then run 'kubectl apply -f k8s/front-end-deployment.yaml'."
Write-Host "=================================================="

# GCP Pause Script
# Pauses the environment to save costs.
# 1. Deletes Load Balancers (saves IP costs)
# 2. Resizes GKE Cluster to 0 nodes (saves Compute costs)
# 3. Stops Legacy VM (saves Compute costs)

$ClusterName = "go-microservices-cluster"
$Zone = "europe-west1-b"
$VmName = "mongo-vm"
$SqlName = "postgres-db"

Write-Host "=================================================="
Write-Host "Pausing GCP Environment..."
Write-Host "=================================================="

# 1. Delete Load Balancers
Write-Host "1. Deleting Load Balancer Services (Broker & Frontend)..."
kubectl delete svc broker-service front-end-service --ignore-not-found
Write-Host "   Load Balancers deleted." -ForegroundColor Green

# 2. Resize GKE Cluster
Write-Host "2. Resizing GKE Cluster to 0 nodes..."
gcloud container clusters resize $ClusterName --num-nodes=0 --zone=$Zone --quiet
Write-Host "   Cluster resized to 0." -ForegroundColor Green

# 3. Stop VM
Write-Host "3. Stopping Mongo VM..."
gcloud compute instances stop $VmName --zone=$Zone --quiet
Write-Host "   VM stopped." -ForegroundColor Green

# 4. Stop Cloud SQL
Write-Host "4. Stopping Cloud SQL..."
gcloud sql instances patch $SqlName --activation-policy=NEVER --quiet
Write-Host "   Cloud SQL Stopped." -ForegroundColor Green

Write-Host "=================================================="
Write-Host "Environment Paused. Storage costs (Disks/Images) still apply."
Write-Host "Run '.\scripts\resume_gcp.ps1' to wake up."
Write-Host "=================================================="

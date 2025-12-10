# cleanup.ps1
# Removes all project resources from GCP

$PROJECT_ID = gcloud config get-value project
$ZONE = "europe-west1-b"
$REGION = "europe-west1"

Write-Host "Starting Cleanup for project $PROJECT_ID..."

# 1. GKE Cluster
Write-Host "Deleting GKE Cluster..."
gcloud container clusters delete go-microservices-cluster --zone=$ZONE --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "Cluster not found or already deleted." }

# 2. Compute VM
Write-Host "Deleting Mongo VM..."
gcloud compute instances delete mongo-vm --zone=$ZONE --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "VM not found or already deleted." }

# 3. Cloud SQL
Write-Host "Deleting Cloud SQL Instance..."
gcloud sql instances delete postgres-db --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "SQL Instance not found or already deleted." }

# 4. Cloud Function
Write-Host "Deleting Cloud Function..."
gcloud functions delete mail-function --region=$REGION --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "Function not found or already deleted." }

Write-Host "Cleanup Complete."

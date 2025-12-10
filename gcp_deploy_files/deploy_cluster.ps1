# deploy_cluster.ps1
# Creates the GKE cluster

$PROJECT_ID = gcloud config get-value project
$ZONE = "europe-west1-b"
$CLUSTER_NAME = "go-microservices-cluster"

Write-Host "Creating GKE Cluster $CLUSTER_NAME..."
gcloud container clusters create $CLUSTER_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --machine-type=e2-medium `
    --num-nodes=2 `
    --network=default `
    --tags=gke-node

Write-Host "Getting credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID

Write-Host "Cluster Deployed and Context Set."

# build_push_images.ps1
# Builds and pushes docker images to Artifact Registry

$PROJECT_ID = gcloud config get-value project
$REGION = "europe-west1"
$REPO = "go-microservices"
$IMAGE_PREFIX = "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO"

# Enable Artifact Registry (just in case)
gcloud services enable artifactregistry.googleapis.com

# Create Repo if not exists (ignore error)
gcloud artifacts repositories create $REPO --repository-format=docker --location=$REGION --description="Microservices Repo"
if ($LASTEXITCODE -ne 0) { Write-Host "Repo probably exists" }

# Configure Docker to use gcloud credentials
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

Write-Host "Building and Pushing Images..."

# Broker
Write-Host "Building Broker..."
docker build -f broker-service.dockerfile -t "$IMAGE_PREFIX/broker-service:1.0.0" .
docker push "$IMAGE_PREFIX/broker-service:1.0.0"

# Auth
Write-Host "Building Auth..."
docker build -f authentication-service.dockerfile -t "$IMAGE_PREFIX/authentication-service:1.0.0" .
docker push "$IMAGE_PREFIX/authentication-service:1.0.0"

# Logger
Write-Host "Building Logger..."
docker build -f logger-service.dockerfile -t "$IMAGE_PREFIX/logger-service:1.0.0" .
docker push "$IMAGE_PREFIX/logger-service:1.0.0"

# Front-End
Write-Host "Building Front-End..."
docker build -f front-end.dockerfile -t "$IMAGE_PREFIX/front-end-service:1.0.6" .
docker push "$IMAGE_PREFIX/front-end-service:1.0.6"

Write-Host "Build and Push Complete."

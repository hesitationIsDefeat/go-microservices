#!/bin/bash
# build_push.sh
# Builds and pushes docker images to Artifact Registry

PROJECT_ID=$(gcloud config get-value project)
REGION="europe-west1"
REPO="go-microservices"
IMAGE_PREFIX="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO"

# Enable Artifact Registry (just in case)
gcloud services enable artifactregistry.googleapis.com

# Create Repo if not exists (ignore error)
gcloud artifacts repositories create $REPO --repository-format=docker --location=$REGION --description="Microservices Repo" || echo "Repo exists"

# Configure Docker to use gcloud credentials
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

echo "Building and Pushing Images..."

# Broker
echo "Building Broker..."
docker build -f broker-service/broker-service.dockerfile -t $IMAGE_PREFIX/broker-service:1.0.0 .
docker push $IMAGE_PREFIX/broker-service:1.0.0

# Auth
echo "Building Auth..."
docker build -f authentication-service/authentication-service.dockerfile -t $IMAGE_PREFIX/authentication-service:1.0.0 .
docker push $IMAGE_PREFIX/authentication-service:1.0.0

# Logger
echo "Building Logger..."
docker build -f logger-service/logger-service.dockerfile -t $IMAGE_PREFIX/logger-service:1.0.0 .
docker push $IMAGE_PREFIX/logger-service:1.0.0

# Front-End
echo "Building Front-End..."
docker build -f front-end/front-end.dockerfile -t $IMAGE_PREFIX/front-end-service:1.0.6 .
docker push $IMAGE_PREFIX/front-end-service:1.0.6

echo "Build and Push Complete."

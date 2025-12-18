#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
IMAGE="gcr.io/$PROJECT_ID/authentication-service:latest"

echo "➡️  Using Google Cloud project: $PROJECT_ID"
echo "➡️  Building Docker image: $IMAGE"

cd ../authentication-service

docker build -t "$IMAGE" .

echo "➡️  Pushing to Container Registry…"
docker push "$IMAGE"

echo "✅ Done!"
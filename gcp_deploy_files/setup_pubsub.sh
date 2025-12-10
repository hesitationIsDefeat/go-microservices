#!/bin/bash

PROJECT_ID="cmpebounproject"
TOPIC_NAME="log-events"
SUBSCRIPTION_NAME="log-sub"
FUNCTION_NAME="processLogFunction"
REGION="europe-west1"

# Create Pub/Sub Topic
echo "Creating Pub/Sub topic: $TOPIC_NAME"
gcloud pubsub topics create $TOPIC_NAME --project=$PROJECT_ID || echo "Topic already exists"

# Create Pub/Sub Subscription for Listener Service
echo "Creating Pub/Sub subscription: $SUBSCRIPTION_NAME"
gcloud pubsub subscriptions create $SUBSCRIPTION_NAME --topic=$TOPIC_NAME --project=$PROJECT_ID || echo "Subscription already exists"

# Deploy Cloud Function
echo "Deploying Cloud Function: $FUNCTION_NAME"
gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime=go121 \
    --region=$REGION \
    --source=./cloud_function \
    --entry-point=ProcessLog \
    --trigger-topic=$TOPIC_NAME \
    --project=$PROJECT_ID

echo "Setup complete!"

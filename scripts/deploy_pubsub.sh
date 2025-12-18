#!/bin/bash

set -e

PROJECT_ID=$(gcloud config get-value project)

echo "Deploying Pub/Sub topics and subscription in project: $PROJECT_ID"

if gcloud pubsub topics describe mail-topic --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "mail-topic already exists"
else
  echo "Creating mail-topic..."
  gcloud pubsub topics create mail-topic --project="$PROJECT_ID"
fi

if gcloud pubsub topics describe logs-topic --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "logs-topic already exists"
else
  echo "Creating logs-topic..."
  gcloud pubsub topics create logs-topic --project="$PROJECT_ID"
fi

if gcloud pubsub subscriptions describe logs-subscription --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "logs-subscription already exists"
else
  echo "Creating logs-subscription..."
  gcloud pubsub subscriptions create logs-subscription \
    --topic=logs-topic \
    --project="$PROJECT_ID" \
    --ack-deadline=20 \
    --message-retention-duration=600s
fi

echo "Pub/Sub deployment completed."

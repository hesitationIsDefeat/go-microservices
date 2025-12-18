#!/bin/bash

set -e

PROJECT_ID=$(gcloud config get-value project)

echo "Deleting Pub/Sub topics and subscription in project: $PROJECT_ID"

if gcloud pubsub subscriptions describe logs-subscription --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Deleting logs-subscription..."
  gcloud pubsub subscriptions delete logs-subscription --project="$PROJECT_ID"
else
  echo "logs-subscription does not exist"
fi

if gcloud pubsub topics describe mail-topic --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Deleting mail-topic..."
  gcloud pubsub topics delete mail-topic --project="$PROJECT_ID"
else
  echo "mail-topic does not exist"
fi

if gcloud pubsub topics describe logs-topic --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Deleting logs-topic..."
  gcloud pubsub topics delete logs-topic --project="$PROJECT_ID"
else
  echo "logs-topic does not exist"
fi

echo "Pub/Sub cleanup completed."

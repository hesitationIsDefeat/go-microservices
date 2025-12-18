#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION="europe-west1"
FUNCTION_NAME="mail-function"
ENTRY_POINT="SendMail"
YAML_PATH="../gke/broker.yaml"

MAIL_HOST="live.smtp.mailtrap.io"
MAIL_PORT="587"
MAIL_USERNAME="smtp@mailtrap.io"
MAIL_PASSWORD="YOUR_REAL_PASSWORD_HERE" 
MAIL_ENCRYPTION="tls"
MAIL_FROM_ADDRESS="hello@demomailtrap.co"
MAIL_FROM_NAME="Thesis Project"

echo "========================================"
echo " Preparing to Deploy HTTP Function: $FUNCTION_NAME"
echo "========================================"

if [ -d "../mail-function" ]; then
    cd "../mail-function"
    echo "✔ Entered directory 'mail-function'."
elif [ -f "go.mod" ]; then
    echo "ℹ️  Found go.mod in current directory."
else
    echo "❌ Error: Directory 'mail-function' not found."
    exit 1
fi

echo "--- Checking Function Status ---"
if gcloud functions describe "$FUNCTION_NAME" --project="$PROJECT_ID" --region="$REGION" --gen2 >/dev/null 2>&1; then
    echo "ℹ️  Function '$FUNCTION_NAME' already exists. Updating..."
else
    echo "ℹ️  Function '$FUNCTION_NAME' not found. Deploying new..."
fi

echo "--- Deploying ---"
gcloud functions deploy "$FUNCTION_NAME" \
  --project="$PROJECT_ID" \
  --gen2 \
  --runtime=go124 \
  --region="$REGION" \
  --source="." \
  --entry-point="$ENTRY_POINT" \
  --trigger-http \
  --allow-unauthenticated \
  --concurrency=1 \
  --max-instances=10 \
  --set-env-vars="MAIL_HOST=${MAIL_HOST},MAIL_PORT=${MAIL_PORT},MAIL_USERNAME=${MAIL_USERNAME},MAIL_PASSWORD=${MAIL_PASSWORD},MAIL_ENCRYPTION=${MAIL_ENCRYPTION},MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS},MAIL_FROM_NAME=${MAIL_FROM_NAME}" \
  --quiet

echo ""
echo "--- Updating Broker Configuration ---"

FUNCTION_URL=$(gcloud functions describe "$FUNCTION_NAME" --project="$PROJECT_ID" --region="$REGION" --gen2 --format="value(serviceConfig.uri)")

echo "📌 Function URL found: $FUNCTION_URL"

if [ -f "$YAML_PATH" ]; then
    if grep -q "MAIL_FUNCTION_URL_PLACEHOLDER" "$YAML_PATH"; then
        sed -i.bak "s|MAIL_FUNCTION_URL_PLACEHOLDER|$FUNCTION_URL|g" "$YAML_PATH"
        rm "$YAML_PATH.bak"
        echo "✔ Successfully updated $YAML_PATH with the Function URL."
    else
        echo "⚠️  Placeholder 'MAIL_FUNCTION_URL_PLACEHOLDER' not found in $YAML_PATH."
    fi
else
    echo "❌ Error: Could not find $YAML_PATH to update."
fi

echo
echo "========================================"
echo " ✅ Cloud Function deployed successfully!"
echo "========================================"
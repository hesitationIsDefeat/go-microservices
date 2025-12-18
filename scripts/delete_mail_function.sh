#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION="europe-west1"
FUNCTION_NAME="mail-function"

YAML_DIR="../gke"
TARGET_FILE="broker.yaml"  
SOURCE_FILE="broker-original.yaml"    

echo "========================================"
echo " Checking for Cloud Function: $FUNCTION_NAME"
echo "========================================"

if gcloud functions describe "$FUNCTION_NAME" --project="$PROJECT_ID" --region="$REGION" --gen2 >/dev/null 2>&1; then
  echo "Found function '$FUNCTION_NAME'. Deleting..."
  
  gcloud functions delete "$FUNCTION_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --gen2 \
    --quiet
    
  echo "✅ Cloud Function deleted successfully!"
else
  echo "⚠️ Function '$FUNCTION_NAME' does not exist. Skipping delete."
fi

echo ""

echo "--- Resetting $TARGET_FILE configuration ---"
if [ -f "$YAML_DIR/$SOURCE_FILE" ]; then
    cp "$YAML_DIR/$SOURCE_FILE" "$YAML_DIR/$TARGET_FILE"
    echo "✔ Successfully copied $SOURCE_FILE to $TARGET_FILE."
    echo "  $TARGET_FILE has been reset to use placeholders (MAIL_FUNCTION_URL_PLACEHOLDER)."
else
    echo "⚠️  WARNING: Could not find '$YAML_DIR/$SOURCE_FILE'."
    echo "   Skipping reset. Please manually revert the URL in $TARGET_FILE."
fi

echo ""
echo "========================================"
echo " Done."
echo "========================================"
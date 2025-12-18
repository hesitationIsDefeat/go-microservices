#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
YAML_DIR="../gke"  

echo "==================================================="
echo " 📝 UPDATING YAML CONFIGS"
echo "==================================================="
echo "Target Project ID: $PROJECT_ID"
echo "Searching in directory: $YAML_DIR"
echo "---------------------------------------------------"

FILES=(
    "broker.yaml" 
    "authentication.yaml" 
    "logger.yaml"
)

for file in "${FILES[@]}"; do
    FILE_PATH="$YAML_DIR/$file"

    if [ -f "$FILE_PATH" ]; then
        echo "Updating $file..."
        
        sed -i '' "s/GOOGLE_CLOUD_PROJECT_PLACEHOLDER/$PROJECT_ID/g" "$FILE_PATH"
        
        if grep -q "$PROJECT_ID" "$FILE_PATH"; then
            echo "  ✔ Success: Placeholder replaced."
        else
            echo "  ⚠️  Warning: Project ID not found in file. Maybe it was already updated?"
        fi
    else
        echo "❌ Error: File '$FILE_PATH' not found."
    fi
done

echo ""
echo "==================================================="
echo " UPDATE COMPLETE"
echo "==================================================="
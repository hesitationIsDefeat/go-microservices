#!/bin/bash
set -e

YAML_DIR="../gke"

echo "==================================================="
echo " 🔄 RESETTING YAML FILES TO ORIGINALS"
echo "==================================================="
echo "Directory: $YAML_DIR"
echo "---------------------------------------------------"

FILES=(
    "broker" 
    "authentication" 
    "logger"
)

for name in "${FILES[@]}"; do
    ORIGINAL="$YAML_DIR/$name-original.yaml"
    TARGET="$YAML_DIR/$name.yaml"

    if [ -f "$ORIGINAL" ]; then
        echo "Resetting $name.yaml..."
        cp "$ORIGINAL" "$TARGET"
        echo "  ✔ Restored from $name-original.yaml"
    else
        echo "⚠️  Skipping $name: Source file '$name-original.yaml' not found."
    fi
done

echo ""
echo "==================================================="
echo " RESET COMPLETE"
echo "==================================================="
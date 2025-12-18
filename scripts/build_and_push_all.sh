#!/bin/bash
set -e

SERVICES=(
  "broker"
  "logger"
  "authentication"
)

echo "========================================"
echo " BUILD & PUSH: All Services"
echo "========================================"

for service in "${SERVICES[@]}"; do
  SCRIPT_PATH="./build_and_push_${service}.sh"

  echo ""
  echo "----------------------------------------"
  echo " Running: $SCRIPT_PATH"
  echo "----------------------------------------"

  if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "❌ ERROR: $SCRIPT_PATH not found!"
    exit 1
  fi

  bash "$SCRIPT_PATH"
done

echo ""
echo "========================================"
echo " ✅ ALL SERVICES BUILT & PUSHED SUCCESSFULLY"
echo "========================================"

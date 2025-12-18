#!/bin/bash
set -e

YAML_DIR="../gke" 
STATIC_IP_NAME="broker-ip"

CPU_TARGET=60
MIN_PODS=1
MAX_PODS=10

echo "========================================"
echo " Deploying Services to GKE + HPA"
echo "========================================"

echo "--- Checking Static IP '$STATIC_IP_NAME' ---"
if gcloud compute addresses describe "$STATIC_IP_NAME" --global >/dev/null 2>&1; then
    echo "ℹ️  IP '$STATIC_IP_NAME' already exists."
else
    echo "Creating global static IP..."
    gcloud compute addresses create "$STATIC_IP_NAME" --global
    echo "✔ IP reserved."
fi

echo "--- Applying Kubernetes Manifests ---"

if [ ! -d "$YAML_DIR" ]; then
    echo "❌ Error: Directory '$YAML_DIR' not found."
    exit 1
fi

echo "Deploying Authentication Service..."
kubectl apply -f "$YAML_DIR/authentication.yaml"

echo "Deploying Logger Service..."
kubectl apply -f "$YAML_DIR/logger.yaml"

echo "Deploying Broker Service..."
kubectl apply -f "$YAML_DIR/broker.yaml"

echo "Deploying Ingress..."
kubectl apply -f "$YAML_DIR/ingress.yaml"

echo ""
echo "--- Configuring Autoscaling (HPA) ---"

apply_hpa() {
    SERVICE=$1
    echo "Configuring HPA for $SERVICE..."
    
    kubectl delete hpa "$SERVICE" --ignore-not-found=true >/dev/null 2>&1
    
    kubectl autoscale deployment "$SERVICE" --cpu-percent=$CPU_TARGET --min=$MIN_PODS --max=$MAX_PODS
}

apply_hpa "broker-service"
apply_hpa "authentication-service"
apply_hpa "logger-service" 

echo ""
echo "--- Forcing Rollout Restart ---"
kubectl rollout restart deployment authentication-service
kubectl rollout restart deployment logger-service
kubectl rollout restart deployment broker-service

echo ""
echo "========================================"
echo " Deployment COMPLETE ✔"
echo "========================================"
echo "Current HPA Status:"
kubectl get hpa
echo ""
echo "Checking Ingress IP status..."
kubectl get ingress broker-ingress
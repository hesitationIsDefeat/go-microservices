# GCP Deployment Guide for Go Microservices

This guide details how to deploy the microservices to Google Cloud Platform using GKE, Pub/Sub, Cloud Functions, and Compute Engine.

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated.
- `kubectl` installed.
- `docker` installed.
- A GCP Project created.

## 1. Environment Setup

Set your project ID:
```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="europe-west1"
gcloud config set project $PROJECT_ID
```

## 2. Build and Push Docker Images

Run the build script to build and push images to Artifact Registry:
```bash
# Make sure to edit gcp/build_images.sh with your PROJECT_ID first!
./gcp/build_images.sh
```

## 3. Setup Pub/Sub and Cloud Function

Run the setup script to create the topic, subscription, and deploy the Cloud Function:
```bash
# Make sure to edit gcp/setup_pubsub.sh with your PROJECT_ID first!
./gcp/setup_pubsub.sh
```

## 4. Create GKE Cluster

Create a standard GKE cluster:
```bash
gcloud container clusters create go-microservices-cluster \
    --zone $REGION-b \
    --num-nodes 3 \
    --machine-type e2-medium
```

Get credentials for `kubectl`:
```bash
gcloud container clusters get-credentials go-microservices-cluster --zone $REGION-b
```

## 5. Deploy to Kubernetes

Apply all manifests:
```bash
# Make sure to replace YOUR_PROJECT_ID in k8s/*.yaml files first!
# You can use sed to do it quickly:
# sed -i 's/YOUR_PROJECT_ID/your-actual-id/g' k8s/*.yaml

kubectl apply -f k8s/
```

Check status:
```bash
kubectl get pods
kubectl get services
```

Get the External IP of the `broker-service`:
```bash
kubectl get svc broker-service
```

## 6. Setup Legacy VM (Optional)

Run the VM setup script:
```bash
# Make sure to edit gcp/vm_setup.sh with your PROJECT_ID first!
./gcp/vm_setup.sh
```

SSH into the VM and run the log processor:
```bash
gcloud compute ssh legacy-vm --zone $REGION-b
# Inside VM:
# Copy content of gcp/log_processor.sh to a file and run it
```

## 7. Verification

1.  Curl the Broker Service IP:
    ```bash
    curl http://<BROKER_EXTERNAL_IP>
    ```
2.  Send a request that triggers a log event (e.g. via the Front End if deployed, or curl).
3.  Check Cloud Function logs to see if it processed the event.
4.  Check Listener Service logs to see if it received the event.

## 8. Cost Management (Pause/Resume)

To save costs when not working on the project, you can "pause" the environment (stop VMs and delete Load Balancers).

### Pause Environment
Run this PowerShell script to stop everything:
```powershell
.\scripts\pause_gcp.ps1
```
*Stops VM, resizes GKE to 0 nodes, deletes Load Balancers.*

### Resume Environment
Run this script to wake everything up:
```powershell
.\scripts\resume_gcp.ps1
```
*Starts VM, resizes GKE to 3 nodes, recreates Load Balancers.*

**IMPORTANT**: After resuming, you will get **NEW External IPs**. You must:
1.  Get the new Broker IP: `kubectl get svc broker-service`
2.  Update `k8s/front-end-deployment.yaml` with the new IP.
3.  Redeploy frontend: `kubectl apply -f k8s/front-end-deployment.yaml`


# Scalable Microservices Backend on GCP

This project deploys a complete microservices architecture (Broker, Auth, Logger) onto Google Kubernetes Engine (GKE), integrated with Cloud SQL, MongoDB, Pub/Sub, and Cloud Functions.

## ⚠️ Prerequisites

Before running any scripts, ensure you have the following installed and running:

1.  **Docker Desktop** (Must be **running** to build images).
2.  **Google Cloud SDK** (`gcloud` CLI).
3.  **kubectl** (Kubernetes CLI).

> **Note:** If Docker is not running, the deployment script will fail when trying to build the containers.

## 🚀 Deployment Guide

Follow these steps to deploy the entire infrastructure from scratch.

### 1. Download the Repository
Clone the repository and switch to the `cmpe48a` branch where the source code is located.

```bash
git clone https://github.com/hesitationIsDefeat/go-microservices.git
cd go-microservices
git checkout cmpe48a
```

### 2. Run the Deployment Script
Navigate to the scripts directory and run the master deployment script. This will provision the GKE cluster, build Docker images, push them to GCR, and deploy all Kubernetes services.

```bash
cd scripts
chmod +x *.sh
./deploy_all.sh
```
*The deployment process usually takes **10-15 minutes**.*

---

## 📡 How to Send a Request

Once deployment is complete, an external Load Balancer (Ingress) is created. You need the **External IP** to talk to the system.

### 1. Get the Ingress IP
Run this command to find the IP address of your broker:
```bash
kubectl get ingress broker-ingress
```
*Look for the `ADDRESS` column (e.g., `34.x.x.x`).*

### 2. Send a Test Request (curl)
Use the IP you found above to send a JSON payload to the broker service:

```bash
curl -X POST http://<YOUR_INGRESS_IP>/test_service_cycle -H "Content-Type: application/json" -d '{"email": "admin@example.com","password": "password"}'
```

---

## 🗑️ Cleanup (Delete Everything)

To avoid Google Cloud charges, remove all resources when you are finished.

```bash
cd scripts
./delete_all.sh
```

> **Warning:** This will permanently delete the GKE cluster, Cloud SQL instance, Mongo VM, and associated Load Balancers. Data on persistent disks will be lost.
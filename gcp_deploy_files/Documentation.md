# Deployment Steps


1. Infrastructure Setup
Run the following scripts (review them first!):

Step 1: Create MongoDB VM

./gcp/deploy_mongo_vm.sh
This creates a VM named mongo-vm with MongoDB exposed internally.
Step 2: Create Cloud SQL Instance

./gcp/deploy_cloud_sql.sh
Note: This takes 10-15 minutes. It sets up a Postgres instance.
Step 3: Deploy Mail Cloud Function

./gcp/deploy_function_mail.sh
This deploys the Go Cloud Function to handle emails via Pub/Sub.

--------------------------------------------------------------------------


2. Build & Push Microservices
Update and push the Docker images for GKE services (broker, 
auth , logger, front-end).

# Example
docker-compose build
docker-compose push
Make sure broker-service is updated because it now contains the new Pub/Sub logic!


------------------------------------------------------------------------

3. Deploy to GKE
Apply the remaining Kubernetes manifests:

- kubectl apply -f k8s/


Verifies that broker, auth , logger, and front-end are running.
The ingress.yml  should be applied to expose the services.
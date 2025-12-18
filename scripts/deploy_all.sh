#!/bin/bash

set -e

echo "=============================="
echo " Deploying ALL GCP Resources "
echo "=============================="

echo ""
echo "--- GCP Setup ---"
./gcp_setup.sh

echo ""
echo "--- Deploying Pub/Sub ---"
./deploy_pubsub.sh

echo ""
echo "--- Deploying Cloud SQL Postgres ---"
./deploy_cloud_sql.sh

echo ""
echo "--- Setting up SQL Proxy Service Account ---"
./create_sql_proxy_sa.sh

echo ""
echo "--- Deploying MongoDB VM ---"
./deploy_mongo_vm.sh

echo ""
echo "--- Deploying Mail Function ---"
./deploy_mail_function.sh

echo ""
echo "--- Deploying GKE ---"
./deploy_gke.sh

echo ""
echo "--- Building and Pushing Docker Images ---"
./build_and_push_all.sh

echo ""
echo "--- Updating YAML files ---"
./update_yaml.sh

echo ""
echo "--- Deploying Services to GKE ---"
./deploy_services.sh

echo ""
echo "=============================="
echo " ALL RESOURCES DEPLOYED ✔"
echo "=============================="

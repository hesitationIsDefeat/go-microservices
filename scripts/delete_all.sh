#!/bin/bash
set -e

echo "=============================="
echo " Deleting ALL GCP Resources "
echo "=============================="

echo ""
echo "--- 1. Deleting Ingress & Load Balancer ---"
./delete_ingress.sh

echo ""
echo "--- 2. Deleting GKE Cluster ---"
./delete_gke.sh

echo ""
echo "--- 3. Deleting Mail Function ---"
./delete_mail_function.sh

echo ""
echo "--- 4. Deleting Pub/Sub ---"
./delete_pubsub.sh

echo ""
echo "--- 5. Deleting Cloud SQL Postgres ---"
./delete_cloud_sql.sh

echo ""
echo "--- 5.1 Cleaning up SQL Proxy Service Account ---"
./cleanup_sql_proxy_sa.sh

echo ""
echo "--- 6. Deleting MongoDB VM ---"
./delete_mongo_vm.sh

echo ""
echo "--- 7. Reset YAML ---"
./reset_yaml.sh

echo ""
echo "=============================="
echo " ALL RESOURCES DELETED ✔"
echo "=============================="
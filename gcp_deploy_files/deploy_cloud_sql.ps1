# deploy_cloud_sql.ps1
# Deploys a Cloud SQL instance for Postgres

$PROJECT_ID = gcloud config get-value project
$REGION = "europe-west1"
$INSTANCE_NAME = "postgres-db"

Write-Host "Creating Cloud SQL Instance (this may take 10-15 minutes)..."
gcloud sql instances create $INSTANCE_NAME `
    --project=$PROJECT_ID `
    --database-version=POSTGRES_14 `
    --tier=db-f1-micro `
    --region=$REGION `
    --root-password=password

Write-Host "Creating 'users' database..."
gcloud sql databases create users --instance=$INSTANCE_NAME

Write-Host "Creating 'postgres' user..."
gcloud sql users set-password postgres --instance=$INSTANCE_NAME --password=password

Write-Host "Cloud SQL Instance Ready."

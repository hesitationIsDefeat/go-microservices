# deploy_function_mail.ps1
# Deploys the Mail Service as a Cloud Function

$PROJECT_ID = gcloud config get-value project
$REGION = "europe-west1"
$FUNCTION_NAME = "mail-function"

# Enable required services
gcloud services enable cloudfunctions.googleapis.com `
    cloudbuild.googleapis.com `
    eventarc.googleapis.com `
    run.googleapis.com `
    logging.googleapis.com `
    pubsub.googleapis.com

# Create the Pub/Sub topic if it doesn't exist
gcloud pubsub topics create send-mail
if ($LASTEXITCODE -ne 0) { Write-Host "Topic send-mail already exists" }

# Deploy the function
Set-Location gcp/cloud_function/mail

Write-Host "Deploying Cloud Function..."
gcloud functions deploy $FUNCTION_NAME `
    --gen2 `
    --region=$REGION `
    --runtime=go121 `
    --source=. `
    --entry-point=ProcessMail `
    --trigger-topic=send-mail `
    --set-env-vars=MAIL_HOST=smtp.gmail.com,MAIL_PORT=587,MAIL_ENCRYPTION=tls,FROM_ADDRESS=noreply@example.com

Write-Host "Deployment complete."

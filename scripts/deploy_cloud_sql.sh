#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
INSTANCE_NAME="postgres-instance"
REGION="europe-west1"

TIER="db-custom-1-3840" 
POSTGRES_VERSION="POSTGRES_14"

DB_NAME="users"
DB_USER="postgres"
DB_PASS="password"

DUMMY_EMAIL="admin@example.com"
DUMMY_PASSWORD="password"
DUMMY_FIRST_NAME="Test"
DUMMY_LAST_NAME="User"

PROXY_PORT=5433

echo "=============================="
echo " Setting up Cloud SQL (Postgres) - PRODUCTION MODE"
echo "=============================="

echo "--- Configuring Environment ---"
gcloud services enable sqladmin.googleapis.com

if command -v cloud-sql-proxy &> /dev/null; then
    PROXY_CMD="cloud-sql-proxy"
elif [ -f "./cloud-sql-proxy" ]; then
    PROXY_CMD="./cloud-sql-proxy"
else
    echo "❌ Error: cloud-sql-proxy not found."
    echo "   Please run: gcloud components install cloud-sql-proxy"
    exit 1
fi
echo "Using Proxy Command: $PROXY_CMD"

pkill cloud-sql-proxy || true
rm -f proxy.log

echo "--- Checking PostgreSQL instance $INSTANCE_NAME ---"
if gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    CURRENT_TIER=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(settings.tier)")
    
    if [ "$CURRENT_TIER" != "$TIER" ]; then
        echo "ℹ️  Instance exists but is on tier '$CURRENT_TIER'."
        echo "🔄 UPGRADING to '$TIER' for load testing (this takes a few minutes)..."
        gcloud sql instances patch "$INSTANCE_NAME" \
            --project="$PROJECT_ID" \
            --tier="$TIER" \
            --quiet
        echo "✔ Upgrade complete."
    else
        echo "ℹ️  Instance already exists and is on correct tier ($TIER)."
    fi
else
    echo "Creating instance ($TIER) - this takes 5–10 minutes..."
    gcloud sql instances create "$INSTANCE_NAME" \
        --project="$PROJECT_ID" \
        --database-version="$POSTGRES_VERSION" \
        --tier="$TIER" \
        --region="$REGION" \
        --availability-type=zonal \
        --storage-size=10GB \
        --no-backup \
        --deletion-protection \
        --assign-ip \
        --quiet
    echo "✔ Instance created."
fi

echo "--- Checking database '$DB_NAME' ---"
if gcloud sql databases list --instance="$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(name)" | grep -q "^$DB_NAME$"; then
    echo "ℹ️  Database already exists."
else
    gcloud sql databases create "$DB_NAME" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" --quiet
    echo "✔ Database created."
fi

echo "--- Configuring user '$DB_USER' ---"
echo "Updating password for '$DB_USER'..."
gcloud sql users set-password "$DB_USER" \
    --instance="$INSTANCE_NAME" \
    --password="$DB_PASS" \
    --project="$PROJECT_ID" \
    --quiet
echo "✔ Password updated."

echo "--- Starting Cloud SQL Auth Proxy on Port $PROXY_PORT ---"
CONNECTION_NAME="$PROJECT_ID:$REGION:$INSTANCE_NAME"

$PROXY_CMD "$CONNECTION_NAME" --port=$PROXY_PORT > proxy.log 2>&1 &
PROXY_PID=$!

echo "Proxy PID: $PROXY_PID"
echo "Waiting 5 seconds for startup..."
sleep 5

if ! ps -p $PROXY_PID > /dev/null; then
    echo "❌ CRITICAL ERROR: The proxy crashed immediately."
    echo "---------------- PROXY LOGS ----------------"
    cat proxy.log
    echo "--------------------------------------------"
    exit 1
fi

echo "--- Connecting to Database (Port $PROXY_PORT) ---"
MAX_RETRIES=5
COUNT=0
SUCCESS=0

while [ $COUNT -lt $MAX_RETRIES ]; do
    set +e 
    PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -p $PROXY_PORT -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        SUCCESS=1
        break
    fi
    set -e
    echo "⚠️  Connection failed. Retrying in 5s... (Check proxy.log if this persists)"
    sleep 5
    COUNT=$((COUNT+1))
done

if [ $SUCCESS -ne 1 ]; then
    echo "❌ Error: Could not connect to database."
    echo "Last 10 lines of proxy log:"
    tail -n 10 proxy.log
    kill "$PROXY_PID"
    exit 1
fi

echo "✔ Connection successful. Creating Table..."

PGPASSWORD="$DB_PASS" psql -h 127.0.0.1 -p $PROXY_PORT -U "$DB_USER" -d "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    password TEXT NOT NULL,
    user_active INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

INSERT INTO users (email, first_name, last_name, password, user_active, created_at, updated_at) 
VALUES ('$DUMMY_EMAIL', '$DUMMY_FIRST_NAME', '$DUMMY_LAST_NAME', '$DUMMY_PASSWORD', 1, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;
EOF

kill "$PROXY_PID"
rm -f proxy.log

echo ""
echo "======================================"
echo " Cloud SQL Setup & Upgrade COMPLETE ✔"
echo "======================================"
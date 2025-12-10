#!/bin/bash

# This script simulates a background process that tails logs
# In a real scenario, this might read from a file or listen to a socket

LOG_FILE="/var/log/syslog"

echo "Starting background log processor..."
echo "Tailing $LOG_FILE..."

tail -f $LOG_FILE | while read line; do
  if [[ "$line" == *"error"* ]]; then
    echo "ALERT: Error found in logs: $line"
    # Here you could send an email or trigger another event
  fi
done

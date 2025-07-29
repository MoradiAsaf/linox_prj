#!/bin/bash

# 📁 Make all .sh scripts executable
find . -name "*.sh" -exec chmod +x {} \;

# Set full path to the daily backup script
BACKUP_SCRIPT_PATH="$(pwd)/daily_backup.sh"

# 1. Start the cron service if available (especially for WSL environments)
if command -v service &>/dev/null; then
  sudo service cron start
fi

# 2. Define the cron job: run the backup script every day at 03:00 AM
CRON_JOB="0 3 * * * /bin/bash $BACKUP_SCRIPT_PATH >> $(pwd)/cron.log 2>&1"

# Check if the job already exists in crontab
(crontab -l 2>/dev/null | grep -F "$BACKUP_SCRIPT_PATH") >/dev/null
if [ $? -ne 0 ]; then
  # If not found, add the job to crontab
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "✔️ Cron job added successfully."
else
  echo "ℹ️ Cron job already exists. No changes made."
fi

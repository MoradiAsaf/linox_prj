#!/bin/bash
# Change to the script's directory (important when running from cron)
cd "$(dirname "$0")"  

# Load utility functions and global variable definitions
source utils.sh

# Set system user context for logging and permission-based functions
export USERNAME="system"
export ROLE="admin"


# Perform data, log, and users file backup with timestamp
export_backup

# Clean up old backups based on retention rules (older than 7 days and not among the two newest)
cleanup_old_backups

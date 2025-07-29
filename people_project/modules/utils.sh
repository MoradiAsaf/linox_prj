#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_FILE="$BASE_DIR/data/data.txt"
LOG_FILE="$BASE_DIR/data/log.txt"
USERS_FILE="$BASE_DIR/data/users.txt"
BACKUP_DIR="$BASE_DIR/backups"


# Validate ID: exactly 9 digits
validate_id() {
  [[ "$1" =~ ^[0-9]{9}$ ]]
}

# Validate name: only letters (Hebrew or English), no commas
validate_name() {
  [[ "$1" =~ ^[a-zA-Z]+$ ]] && [[ "$1" != *","* ]]
}

# Write to log file with timestamp and user info
log_action() {
  local action="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$USERNAME | $ROLE] $action" >> "$LOG_FILE"
}

# Get current timestamp for filenames
get_current_timestamp() {
  date '+%Y-%m-%d_%H-%M-%S'
}

# Count number of records
count_records() {
  if [ ! -f "$DATA_FILE" ]; then
    echo "No data file found."
    return
  fi

  count=$(wc -l < "$DATA_FILE")
  echo "Total records: $count"
  log_action "Checked record count: $count"
}

# Export backups of data, log, and users file
export_backup() {
  mkdir -p "$BACKUP_DIR"
  timestamp=$(get_current_timestamp)

  cp "$DATA_FILE" "$BACKUP_DIR/data_backup_$timestamp.txt"
  cp "$LOG_FILE" "$BACKUP_DIR/log_backup_$timestamp.txt"
  cp "$USERS_FILE" "$BACKUP_DIR/users_backup_$timestamp.txt"

  echo "Backups saved to: $BACKUP_DIR/"
  echo " - data_backup_$timestamp.txt"
  echo " - log_backup_$timestamp.txt"
  echo " - users_backup_$timestamp.txt"

  log_action "Exported backup (data, log, users) with timestamp $timestamp"
}

# מחיקת גיבויים ישנים עם תנאים
cleanup_old_backups() {
  files=($(ls -1t "$BACKUP_DIR"/data_backup_*.txt 2>/dev/null))  # מיון מהחדש לישן

  for file in "${files[@]}"; do
    file_time=$(date -r "$file" +%s)
    now=$(date +%s)
    age_days=$(( (now - file_time) / 86400 ))

    # אם עברו 7 ימים ויש לפחות שניים חדשים ממנו
    if [[ "$age_days" -gt 7 ]]; then
      # מצא את המיקום שלו במערך
      for i in "${!files[@]}"; do
        if [[ "${files[$i]}" == "$file" ]]; then
          index=$i
          break
        fi
      done

      newer_count=$index  # כי הרשימה ממוינת מהחדש לישן

      if [[ "$newer_count" -ge 2 ]]; then
        rm "$file"
        log_action "Old backup deleted: $(basename "$file")"
      fi
    fi
  done
}

restore_backup() {
  echo "Available backups:"
  select backup_file in $(ls backups/data_backup_*.txt 2>/dev/null); do
    if [[ -n "$backup_file" ]]; then
      base_name=$(basename "$backup_file" | sed 's/data_backup_//' | sed 's/.txt//')

      echo ""
      echo "⚠️  You are about to restore the system from: $base_name"
      read -p "Are you sure you want to proceed? This will overwrite current data, logs, and users. (y/n): " confirm
      if [[ "$confirm" != "y" ]]; then
        echo "Restore canceled."
        log_action "Restore canceled for backup: $base_name"
        return
      fi

      # Backup current state before restore
      timestamp=$(date +%Y%m%d_%H%M%S)
      cp "$DATA_FILE" "backups/data_backup_${timestamp}_before_restore.txt"
      cp "$LOG_FILE" "backups/log_backup_${timestamp}_before_restore.txt"
      cp "$USERS_FILE" "backups/users_backup_${timestamp}_before_restore.txt"
      echo "Current state backed up before restore."

      # Restore files
      cp "backups/data_backup_$base_name.txt" "$DATA_FILE"
      cp "backups/log_backup_$base_name.txt" "$LOG_FILE"
      cp "backups/users_backup_$base_name.txt" "$USERS_FILE"

      echo "✅ System restored from backup: $base_name"
      log_action "Restored system from backup: $base_name"
      return
    else
      echo "Invalid selection."
    fi
  done
}


change_own_password() {
  echo "Change your password"
  read -s -p "Enter current password: " current_pass
  echo ""
  hashed_current=$(hash_password "$current_pass")
  if ! grep -q "^$USERNAME,$hashed_current," "$USERS_FILE"; then
    echo "Current password is incorrect."
    return
  fi
  
  read -s -p "Enter new password: " new_pass
  echo ""
  read -s -p "Confirm new password: " confirm_pass
  echo ""

  if [[ "$new_pass" != "$confirm_pass" ]]; then
    echo "Passwords do not match."
    return
  fi

  hashed_new=$(hash_password "$new_pass")



  # Update password
  tmpfile=$(mktemp)
  while IFS=, read -r user pass role; do
    if [[ "$user" == "$USERNAME" ]]; then
      echo "$user,$hashed_new,$role" >> "$tmpfile"
    else
      echo "$user,$pass,$role" >> "$tmpfile"
    fi
  done < "$USERS_FILE"
  mv "$tmpfile" "$USERS_FILE"

  echo "Password updated successfully."
  log_action "[USER] $USERNAME changed their password"
}

edit_user_details() {
  echo "Edit your username"
  read -p "Enter new username: " new_username

  if [[ "$new_username" == "$USERNAME" ]]; then
    echo "New username is the same as the current one."
    return
  fi

  if grep -q "^$new_username," "$USERS_FILE"; then
    echo "Username already exists."
    return
  fi

  tmpfile=$(mktemp)
  while IFS=, read -r user pass role; do
    if [[ "$user" == "$USERNAME" ]]; then
      echo "$new_username,$pass,$role" >> "$tmpfile"
    else
      echo "$user,$pass,$role" >> "$tmpfile"
    fi
  done < "$USERS_FILE"
  mv "$tmpfile" "$USERS_FILE"

  log_action "[USER] $USERNAME changed username to $new_username"
  USERNAME="$new_username"
  export USERNAME

  echo "Username updated successfully. Your new username is: $USERNAME"
}

#!/bin/bash

# Add a new person to the data file
add_person() {
  read -p "Enter ID (9 digits): " id
  if ! validate_id "$id"; then
    echo "Invalid ID. Must be 9 digits."
    return
  fi

  # Check for duplicate ID
  if grep -q "^$id," "$DATA_FILE"; then
    echo "ID already exists."
    return
  fi

  # Prompt for first name
  read -p "Enter first name: " fname
  if ! validate_name "$fname"; then
    echo "Invalid first name."
    return
  fi

  # Prompt for last name
  read -p "Enter last name: " lname
  if ! validate_name "$lname"; then
    echo "Invalid last name."
    return
  fi

  # Add record to data file
  timestamp=$(get_current_timestamp)
  echo "$id,$fname,$lname,$timestamp" >> "$DATA_FILE"
  echo "Person added successfully."
  log_action "[$CURRENT_USER | $ROLE] Added person: ID=$id, First=$fname, Last=$lname"
}

# Display all records with sorting options
show_all_records() {
  if [ ! -f "$DATA_FILE" ]; then
    echo "No records found."
    return
  fi

  echo "Sort by:"
  echo "1. ID"
  echo "2. First name"
  echo "3. Last name"
  echo "4. Creation date"
  read -p "Enter choice: " sort_choice

  case $sort_choice in
    1) sort -t',' -k1 "$DATA_FILE" ;;
    2) sort -t',' -k2 "$DATA_FILE" ;;
    3) sort -t',' -k3 "$DATA_FILE" ;;
    4) sort -t',' -k4 "$DATA_FILE" ;;
    *) echo "Invalid choice. Showing unsorted."; cat "$DATA_FILE" ;;
  esac

  log_action "[$CURRENT_USER | $ROLE] Viewed all records (sorted by $sort_choice)"
}

# Search a single person by ID, first name, or last name
search_single() {
  echo "Search by:"
  echo "1. ID"
  echo "2. First name"
  echo "3. Last name"
  read -p "Enter choice: " field

  case $field in
    1)
      read -p "Enter ID: " id
      result=$(grep "^$id," "$DATA_FILE" | head -n 1)
      echo "${result:-No match found.}"
      log_action "[$CURRENT_USER | $ROLE] Searched by ID: $id"
      ;;
    2)
      read -p "Enter first name: " fname
      result=$(grep ",$fname," "$DATA_FILE")
      echo "${result:-No match found.}"
      log_action "[$CURRENT_USER | $ROLE] Searched by first name: $fname"
      ;;
    3)
      read -p "Enter last name: " lname
      result=$(grep ",$lname," "$DATA_FILE")
      echo "${result:-No match found.}"
      log_action "[$CURRENT_USER | $ROLE] Searched by last name: $lname"
      ;;
    *)
      echo "Invalid choice."
      ;;
  esac
}

# Delete a person record by ID
delete_person() {
  read -p "Enter ID to delete: " id
  if ! grep -q "^$id," "$DATA_FILE"; then
    echo "ID not found."
    return
  fi

  read -p "Are you sure you want to delete this record? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Deletion cancelled."
    log_action "[$CURRENT_USER | $ROLE] Canceled deletion for ID: $id"
    return
  fi

  # Remove the line matching the ID
  temp_file=$(mktemp)
  grep -v "^$id," "$DATA_FILE" > "$temp_file"
  mv "$temp_file" "$DATA_FILE"
  echo "Record deleted."
  log_action "[$CURRENT_USER | $ROLE] Deleted person with ID: $id"
}

# View the system log (admin only)
view_log() {
  if [ ! -f "$LOG_FILE" ]; then
    echo "No log file found."
    return
  fi

  echo "Log file content:"
  echo "------------------"
  cat "$LOG_FILE"
  log_action "[$CURRENT_USER | $ROLE] Viewed log file"
}

# Manage users (available to manager and admin)
manage_users() {
  echo ""
  echo "User Management:"
  echo "1. Add user"
  echo "2. List users"
  echo "3. Delete user"
  read -p "Choose option: " opt

  case $opt in
    1)
      source add_user.sh
      log_action "[$CURRENT_USER | $ROLE] Triggered add_user.sh"
      ;;
    2)
      echo ""
      echo "Username | Role"
      echo "----------------"
      cut -d',' -f1,3 users.txt | column -t -s ','
      log_action "[$CURRENT_USER | $ROLE] Viewed users list"
      ;;
    3)
      read -p "Enter username to delete: " uname

      # Prevent deletion of the admin account
      if [[ "$uname" == "admin" ]]; then
        echo "You cannot delete the admin account."
        return
      fi

      user_role=$(grep "^$uname," users.txt | cut -d',' -f3)

      if [[ -z "$user_role" ]]; then
        echo "User not found."
        return
      fi

      # Managers can only delete regular users
      if [[ "$ROLE" == "manager" && "$user_role" != "user" ]]; then
        echo "Managers can only delete users."
        return
      fi

      grep -v "^$uname," users.txt > temp && mv temp users.txt
      echo "User '$uname' deleted."
      log_action "[$CURRENT_USER | $ROLE] Deleted user '$uname'"
      ;;
    *)
      echo "Invalid choice."
      ;;
  esac
}

# Export all data to a CSV file with a timestamp
export_to_csv() {
  if [ ! -f "$DATA_FILE" ]; then
    echo "No data to export."
    return
  fi

  timestamp=$(date +%Y%m%d_%H%M%S)
  csv_file="export_${timestamp}.csv"
  cp "$DATA_FILE" "$csv_file"

  echo "Data exported to $csv_file"
  log_action "Exported data to CSV ($csv_file)"
}

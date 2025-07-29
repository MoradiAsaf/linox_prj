#!/bin/bash

# Load all module scripts (authentication, utilities, core logic, user management)
source modules/auth.sh
source modules/utils.sh
source modules/logic.sh
source modules/manage_users.sh

# Start the login process (sets USERNAME and ROLE)
login
log_action "[LOGIN] $USERNAME ($ROLE) logged in"

echo ""
echo "Welcome, $USERNAME! Role: $ROLE"
echo ""

# Start the main menu loop
while true; do
  echo ""
  echo "===== Main Menu ====="
  echo "1. Add new person"
  echo "2. Show all records"
  echo "3. Search person"
  echo "4. Count total records"
  echo "5. Export data to CSV"
  echo "6. Change your password"
  echo "7. Change your username"
  
  # Show management option only for manager or admin
  if [[ "$ROLE" == "manager" || "$ROLE" == "admin" ]]; then
    echo "8. System Management"
  fi
  echo "0. Logout"

  # Read user input
  read -p "Enter your choice: " choice
  echo ""

  case $choice in
    1) add_person ;;             # Add a new person record
    2) show_all_records ;;       # Show all person records
    3) search_single ;;          # Search for a person
    4) count_records ;;          # Count total number of records
    5) export_to_csv ;;          # Export data to CSV file
    6) change_own_password ;;    # Change current user's password
    7) edit_user_details ;;      # Edit current user's username
    8)
      # System management menu (only for manager/admin)
      if [[ "$ROLE" == "manager" || "$ROLE" == "admin" ]]; then
        while true; do
          echo ""
          echo "===== System Management Menu ====="
          echo "1. Delete person by ID"
          echo "2. View system log"
          echo "3. Export full backup"
          echo "4. Restore from backup"
          echo "5. Manage users"
          echo "0. Return to main menu"

          read -p "Enter your choice: " admin_choice
          echo ""

          case $admin_choice in
            1) delete_person ;;     # Delete a person by ID
            2) view_log ;;          # View the log file
            3) export_backup ;;     # Perform system backup
            4) restore_backup ;;    # Restore from a previous backup
            5) manage_users ;;      # Enter user management interface
            0) break ;;             # Return to main menu
            *) echo "⚠️ Invalid choice." ;;
          esac
        done
      else
        echo "⚠️ You do not have permission to access this menu."
      fi
      ;;
    0)
      # Logout and exit the script
      echo "Logging out..."
      log_action "[LOGOUT] $USERNAME ($ROLE) logged out"
      exit
      ;;
    *)
      echo "⚠️ Invalid choice."
      ;;
  esac
done

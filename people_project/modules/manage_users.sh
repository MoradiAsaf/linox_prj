#!/bin/bash

# Load utility functions and constants (e.g., USERS_FILE, log_action)
source "$(dirname "$BASH_SOURCE")/utils.sh"

# Display user management main menu
manage_users() {
  while true; do
    echo "--- User Management Menu ---"
    echo "1. List all users"
    echo "2. Add new user"
    echo "3. Edit user role (admin only)"
    echo "4. Reset user password"
    echo "5. Delete user"
    echo "0. Back to main menu"

    read -p "Enter your choice: " choice
    echo ""

    case $choice in
      1) list_users ;;  # Option to view all users
      2) add_user ;;    # Option to add a new user
      3)
        # Only admin can change user roles
        if [[ "$ROLE" == "admin" ]]; then
          edit_user_role
        else
          echo "Only admin can edit roles."
        fi
        ;;
      4)
        # Role-based permission check before password reset
        read -p "Enter username to reset password for: " target
        target_role=$(grep "^$target," "$USERS_FILE" | cut -d',' -f3)

        if [[ "$ROLE" == "admin" ]]; then
          reset_user_password "$target"
        elif [[ "$ROLE" == "manager" && "$target_role" == "user" ]]; then
          reset_user_password "$target"
        else
          echo "You do not have permission to reset this user's password."
        fi
        ;;
      5) delete_user ;;  # Delete user by username
      0) break ;;         # Exit back to main menu
      *) echo "Invalid choice." ;;
    esac

    echo ""
  done
}

# List all users with their roles
list_users() {
  echo "Username, Role"
  echo "----------------"
  cut -d',' -f1,3 "$USERS_FILE"
  log_action "Listed all users"
}

# Add a new user (runs the add_user.sh script)
add_user() {
  source "$(dirname "${BASH_SOURCE[0]}")/add_user.sh"
  log_action "New user added via manage_users"
}

# Edit the role of a user (admin only)
edit_user_role() {
  read -p "Enter username to edit: " user

  if ! grep -q "^$user," "$USERS_FILE"; then
    echo "User not found."
    return
  fi

  read -p "Enter new role (user/manager): " new_role
  if [[ "$new_role" != "user" && "$new_role" != "manager" ]]; then
    echo "Invalid role."
    return
  fi

  # Update the role in the users file
  awk -F',' -v u="$user" -v r="$new_role" 'BEGIN {OFS=","} {
    if ($1==u) $3=r; print
  }' "$USERS_FILE" > tmp && mv tmp "$USERS_FILE"

  echo "Role updated for user '$user' to '$new_role'."
  log_action "Updated role for user '$user' to '$new_role'"
}

# Reset a user's password (must be authorized before calling)
reset_user_password() {
  local user="$1"

  if ! grep -q "^$user," "$USERS_FILE"; then
    echo "User not found."
    return
  fi

  # Prompt for new password (and confirm)
  read -s -p "Enter new password: " new_pass
  echo ""
  read -s -p "Confirm password: " confirm_pass
  echo ""

  if [[ "$new_pass" != "$confirm_pass" ]]; then
    echo "Passwords do not match."
    return
  fi

  # Encrypt and update password
  hashed=$(echo -n "$new_pass" | sha256sum | awk '{print $1}')

  awk -F',' -v u="$user" -v p="$hashed" 'BEGIN {OFS=","} {
    if ($1==u) $2=p; print
  }' "$USERS_FILE" > tmp && mv tmp "$USERS_FILE"

  echo "Password updated for user '$user'."
  log_action "Password reset for user '$user'"
}

# Delete a user from the system
delete_user() {
  read -p "Enter username to delete: " user

  # Prevent users from deleting their own account
  if [[ "$user" == "$USERNAME" ]]; then
    echo "You cannot delete your own account."
    return
  fi

  if ! grep -q "^$user," "$USERS_FILE"; then
    echo "User not found."
    return
  fi

  # Delete user line from users file
  sed -i "/^$user,/d" "$USERS_FILE"
  echo "User '$user' deleted."
  log_action "Deleted user '$user'"
}

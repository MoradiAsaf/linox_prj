#!/bin/bash

# Ensure the script is being run by a context that has ROLE and USERNAME defined
if [[ -z "$ROLE" || -z "$USERNAME" ]]; then
  echo "Error: ROLE or USERNAME not set."
  exit 1
fi

# Prompt for a new username
read -p "Enter new username: " username

# Validate the username: only letters, numbers, and underscore allowed
if ! [[ "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
  echo "Invalid username. Only letters, numbers and underscore allowed."
  exit 1
fi

# Check if the username already exists in the users file
if grep -q "^$username," "$USERS_FILE"; then
  echo "User already exists."
  exit 1
fi

# Prompt for password and confirmation (silent input)
read -s -p "Enter password: " password
echo ""
read -s -p "Confirm password: " confirm
echo ""

# Check for empty password
if [[ -z "$password" ]]; then
  echo "Password cannot be empty."
  exit 1
fi

# Check for password mismatch
if [[ "$password" != "$confirm" ]]; then
  echo "Passwords do not match."
  exit 1
fi

# Determine user role: only admins can create 'manager' users
if [[ "$ROLE" == "admin" ]]; then
  read -p "Enter role (user/manager): " new_role
else
  new_role="user"
  echo "Only 'user' role allowed. Assigned automatically."
fi

# Validate the chosen role
if [[ "$new_role" != "user" && "$new_role" != "manager" ]]; then
  echo "Invalid role."
  exit 1
fi

# Restrict creation of manager accounts to admins only
if [[ "$new_role" == "manager" && "$ROLE" != "admin" ]]; then
  echo "Only admin can create manager accounts."
  exit 1
fi

# Encrypt (hash) the password using SHA256
hashed_pass=$(echo -n "$password" | sha256sum | awk '{print $1}')

# Append the new user to the users file
echo "$username,$hashed_pass,$new_role" >> "$USERS_FILE"
echo "User '$username' with role '$new_role' added successfully."

# Log the user addition
log_action "Added user: $username with role $new_role"

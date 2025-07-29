#!/bin/bash

# Function to hash a password using SHA256 (no newline)
hash_password() {
  echo -n "$1" | sha256sum | awk '{print $1}'
}

# Login function: prompts for username and password, verifies credentials,
# and sets USERNAME and ROLE environment variables upon successful login
login() {
  # Prompt user for credentials
  read -p "Username: " input_user
  read -s -p "Password: " input_pass
  echo ""

  # Check if the users file exists
  if [ ! -f "$USERS_FILE" ]; then
    echo "Users file not found."
    exit 1
  fi

  # Hash the entered password
  hashed_input=$(hash_password "$input_pass")
  local found=0

  # Read users file line by line: username,password_hash,role
  while IFS=, read -r username password_hash role; do
    # Check for matching username and password hash
    if [[ "$input_user" == "$username" && "$hashed_input" == "$password_hash" ]]; then
      USERNAME="$username"
      ROLE="$role"
      export USERNAME ROLE  # Make variables accessible in current session
      found=1
      return 0
    fi
  done < "$USERS_FILE"

  # If no match found, show error and log the failed attempt
  if [[ $found -eq 0 ]]; then
    log_action "Login failed for user: $input_user"
    echo "Login failed. Invalid username or password."
    exit 1
  fi
}

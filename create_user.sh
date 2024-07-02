#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Check if the input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1
fi

INPUT_FILE=$1

# Log and password files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create /var/secure directory if it doesn't exist and set permissions
mkdir -p /var/secure
chmod 700 /var/secure

# Function to generate a random password
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Process the input file
while IFS=';' read -r username groups; do
  # Remove leading/trailing whitespace
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)

  # Skip empty lines or lines without a username
  if [ -z "$username" ]; then
    continue
  fi

  # Check if the user already exists
  if id "$username" &>/dev/null; then
    echo "User $username already exists. Skipping..." | tee -a "$LOG_FILE"
    continue
  fi

  # Create the user with a home directory
  useradd -m "$username" | tee -a "$LOG_FILE"

  # Set the user's primary group
  usermod -g "$username" "$username" | tee -a "$LOG_FILE"

  # Add the user to additional groups
  if [ -n "$groups" ]; then
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
      group=$(echo "$group" | xargs)
      if ! getent group "$group" >/dev/null; then
        groupadd "$group" | tee -a "$LOG_FILE"
      fi
      usermod -aG "$group" "$username" | tee -a "$LOG_FILE"
    done
  fi

  # Generate a random password
  password=$(generate_password)
  echo "$username:$password" | chpasswd | tee -a "$LOG_FILE"

  # Store the username and password securely
  echo "$username,$password" >> "$PASSWORD_FILE"

  # Set ownership and permissions for the home directory
  chown -R "$username:$username" "/home/$username" | tee -a "$LOG_FILE"
  chmod 700 "/home/$username" | tee -a "$LOG_FILE"

  echo "Created user $username with groups $groups" | tee -a "$LOG_FILE"

done < "$INPUT_FILE"

# Secure the password file
chmod 600 "$PASSWORD_FILE"

echo "User creation process completed." | tee -a "$LOG_FILE"



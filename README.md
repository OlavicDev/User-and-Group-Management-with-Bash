# User-and-Group-Management-with-Bash

## Automating User and Group Management with Bash

As a SysOps engineer, managing user accounts efficiently is crucial, especially in an environment with many new developers joining the team. This article explains a Bash script designed to automate user creation, assign groups, set up home directories, and handle user passwords securely. This script is particularly useful for ensuring consistency and reducing manual administrative tasks.

## Script Overview
The script, create_users.sh, reads a text file containing usernames and group names, where each line is formatted as user;groups. The script performs the following tasks:

### User and Group Creation:
Checks if the user already exists and skips the creation if so.
Creates a user with a home directory and assigns a primary group with the same name as the username.
Adds the user to additional groups as specified in the input file.

### Home Directory Setup:
Sets appropriate ownership and permissions for the user's home directory to ensure security.
Password Management:

### Generates random passwords for the users.
Stores the generated passwords securely in `/var/secure/user_passwords.csv` with restricted access.

### Logging:
Logs all actions performed by the script to `/var/log/user_management.log.`


## Steps to Create the Script
Ensure the Script is Run as Root:

The script checks if it is being run as root, as creating users and modifying system files requires root privileges.
```
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
```
Check for Input File:
Validates that an input file is provided as an argument to the script.
```
if [ -z "$1" ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1
fi

INPUT_FILE=$1
```

Initialize Log and Password Files:
Defines log and password files, creates the /var/secure directory if it doesn't exist, and sets appropriate permissions.
```
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

mkdir -p /var/secure
chmod 700 /var/secure
```

Password Generation Function:
Defines a function to generate a random 12-character password.
```
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}
```

Process the Input File:
Reads each line from the input file, extracts the username and groups, and processes them.
```
while IFS=';' read -r username groups; do
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)

  if [ -z "$username" ]; then
    continue
  fi

  if id "$username" &>/dev/null; then
    echo "User $username already exists. Skipping..." | tee -a "$LOG_FILE"
    continue
  fi

  useradd -m "$username" | tee -a "$LOG_FILE"
  usermod -g "$username" "$username" | tee -a "$LOG_FILE"

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

  password=$(generate_password)
  echo "$username:$password" | chpasswd | tee -a "$LOG_FILE"
  echo "$username,$password" >> "$PASSWORD_FILE"
  chown -R "$username:$username" "/home/$username" | tee -a "$LOG_FILE"
  chmod 700 "/home/$username" | tee -a "$LOG_FILE"

  echo "Created user $username with groups $groups" | tee -a "$LOG_FILE"

done < "$INPUT_FILE"
```

Secure the Password File:
Ensures that the password file has restricted permissions so only the file owner can read it.
```
chmod 600 "$PASSWORD_FILE"
echo "User creation process completed." | tee -a "$LOG_FILE"
```
Running the Script
To run the script, ensure you have the input file formatted correctly, for example:
```
light; sudo,dev,www-data
idimma; sudo
mayowa; dev,www-data
Execute the script with root privileges:
```
```
sudo bash create_users.sh <name-of-text-file>
```

## Running the code in general and comfirming it 

### Create the Script:
Open a terminal.

Create a new file named `create_users.sh`:
```
sudo vim create_users.sh
```
Copy and paste the script content above into the create_users.sh file.

Save the file and exit the editor.

### Make the Script Executable:
Make the script executable by running the following command:

```
sudo chmod +x create_users.sh
```

### Create the Input File:
Create a new text file with the usernames and groups. For example, create a file named users.txt:
```
sudo nano users.txt
```
Add the user information in the following format and save the file:
```
light; sudo,dev,www-data
idimma; sudo
mayowa; dev,www-data
```

### Run the Script:
Execute the script by providing the name of the input file as an argument. Ensure you run the script with root privileges:

```
sudo ./create_users.sh users.txt
```

### Verify the Output:
Check the log file to verify the actions performed by the script:

```
sudo cat /var/log/user_management.log
```
Check the password file to see the generated passwords:
```
sudo cat /var/secure/user_passwords.csv
```

## Conclusion
This script simplifies the user and group management process, making it more efficient and secure. Automating these tasks reduces the risk of human error and ensures that all users are set up consistently. For more information about similar projects and learning opportunities, check out the HNG Internship and HNG Hire programs.

This article and script help SysOps engineers streamline their workflow, ensuring that new users are added to the system securely and efficiently.

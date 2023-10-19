# This script creates a new user and sets the password to a randomly generated character that expires on the first attempt.
#!/bin/bash

# Prompt for user input
read -p "Enter the username: " username
read -p "Enter the public SSH key: " public_key

echo "Creating new user..."
mkdir -p "/home/$username/.ssh"
touch "/home/$username/.ssh/authorized_keys"
useradd -d "/home/$username" -s /bin/bash "$username"
usermod -aG sudo "$username"
chown -R "$username:$username" "/home/$username"
echo "Setting up relevant permissions..."
chown root:root "/home/$username"
chmod 700 "/home/$username/.ssh"
chmod 644 "/home/$username/.ssh/authorized_keys"

# Generate a random password
random_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
echo "Setting up user's random password..."
echo "$username:$random_password" | chpasswd

# Expire the password for first login attempt
passwd -e "$username"

# Print user's home directory
echo "User's home directory: $HOME"

# Add public SSH key to authorized_keys
echo "Adding your SSH key..."
echo "$public_key" >> "/home/$username/.ssh/authorized_keys"

# Finalizing script
echo "Finalizing and cleaning up..."
echo "New user can now login with the random password: $random_password, which will be expired on the first login. Goodbye :-)"

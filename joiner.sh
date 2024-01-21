#!/bin/bash

# Function to install jq
install_jq() {
    echo "Installing jq..."
    sudo apt-get update && sudo apt-get install -y jq
    echo "jq installed successfully."
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    install_jq
else
    echo "jq is already installed."
fi

# Function to install MicroK8s
install_microk8s() {
    echo "Installing MicroK8s..."
    sudo snap install microk8s --classic
    echo "MicroK8s installed successfully."
}

# Check if MicroK8s is installed
if ! command -v microk8s &> /dev/null; then
    install_microk8s
else
    echo "MicroK8s is already installed."
fi

# Get the hostname of the system
HOSTNAME=$(hostname)

# Get the primary IP address of the system
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Check if the entry already exists in /etc/hosts
if ! grep -q "$IP_ADDRESS $HOSTNAME" /etc/hosts; then
    # Append the IP and hostname to /etc/hosts
    echo "$IP_ADDRESS $HOSTNAME" | sudo tee -a /etc/hosts
else
    echo "Entry already exists in /etc/hosts"
fi

# Execute the curl command to get join command and store the response
RESPONSE=$(curl -s "http://10.51.0.161:8081/get-join-command?hostname=$HOSTNAME")

# Parse the join command from the response
JOIN_COMMAND=$(echo $RESPONSE | jq -r '.join_command')

# Check if the join command was received
if [ -n "$JOIN_COMMAND" ]; then
    # Append --skip-verify to the join command and execute it
    FULL_COMMAND="$JOIN_COMMAND --skip-verify"
    echo "Executing join command: $FULL_COMMAND"
    eval $FULL_COMMAND
else
    echo "Failed to retrieve join command."
fi

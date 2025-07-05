#!/bin/bash

# Make this executable: chmod +x ~/scripts/autopair

# Get the directory where this script is located
SCRIPT_DIR="/home/pi/radio-pi"
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the .env file from the same directory
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Found .env file"
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found in $SCRIPT_DIR"
    echo "Please create a .env file with MAC_ADDRESS=your_bluetooth_mac_address"
    exit 1
fi

# Check if MAC_ADDRESS is set
if [ -z "$MAC_ADDRESS" ]; then
    echo "Error: MAC_ADDRESS not set in .env file"
    echo "Please add MAC_ADDRESS=your_bluetooth_mac_address to .env"
    exit 1
fi

bluetoothctl connect $MAC_ADDRESS
#!/bin/bash

# Bluetooth Connection Manager
# Continuously monitors and manages Bluetooth device connection
# Reads MAC address from .env file and ensures device is paired, trusted, and connected

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT_NAME="$(basename "$0")"
LOCK_FILE="/tmp/${SCRIPT_NAME}.lock"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/connect-speaker.log"


# Logging function
log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$level] - $*" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "INFO" "Cleaning up..."
    rm -f "$LOCK_FILE"
    exit $exit_code
}

# Signal handlers
trap cleanup EXIT
trap 'log "INFO" "Interrupted by user. Exiting gracefully..."; exit 130' INT TERM

# Check if script is already running
check_if_running() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log "INFO" "Script already running with PID $pid. Exiting."
            exit 0
        else
            log "WARN" "Stale lock file found. Removing..."
            rm -f "$LOCK_FILE"
        fi
    fi
    
    # Create lock file with current PID
    echo $$ > "$LOCK_FILE"
}

# Load configuration from .env file
load_config() {
    local env_file="$ROOT_DIR/.env"
    
    if [ ! -f "$env_file" ]; then
        log "ERROR" ".env file not found in $ROOT_DIR"
        log "ERROR" "Please create a .env file with MAC_ADDRESS=your_bluetooth_mac_address"
        exit 1
    fi
    
    # Source the .env file
    source "$env_file"
    
    # Check if MAC_ADDRESS is set
    if [ -z "${MAC_ADDRESS:-}" ]; then
        log "ERROR" "MAC_ADDRESS not set in .env file"
        log "ERROR" "Please add MAC_ADDRESS=your_bluetooth_mac_address to .env"
        exit 1
    fi
    
    # Validate MAC address format
    if ! echo "$MAC_ADDRESS" | grep -E '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$' > /dev/null; then
        log "ERROR" "Invalid MAC address format: $MAC_ADDRESS"
        log "ERROR" "Expected format: AA:BB:CC:DD:EE:FF"
        exit 1
    fi
    
    log "INFO" "Loaded configuration - MAC Address: $MAC_ADDRESS"
}

# Check if device is paired
is_paired() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes"
}

# Check if device is trusted
is_trusted() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Trusted: yes"
}

# Check if device is connected
is_connected() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"
}

# Pair device
pair_device() {
    local mac="$1"
    log "INFO" "Attempting to pair with device $mac..."
    
    # Make sure bluetooth is powered on
    bluetoothctl power on > /dev/null 2>&1
    sleep 2
    
    # Make discoverable temporarily
    bluetoothctl discoverable on > /dev/null 2>&1
    
    # Attempt to pair
    if timeout 30 bluetoothctl pair "$mac" > /dev/null 2>&1; then
        log "INFO" "Successfully paired with $mac"
        return 0
    else
        log "ERROR" "Failed to pair with $mac"
        return 1
    fi
}

# Trust device
trust_device() {
    local mac="$1"
    log "INFO" "Trusting device $mac..."
    
    if bluetoothctl trust "$mac" > /dev/null 2>&1; then
        log "INFO" "Successfully trusted $mac"
        return 0
    else
        log "ERROR" "Failed to trust $mac"
        return 1
    fi
}

# Connect to device
connect_device() {
    local mac="$1"
    log "INFO" "Attempting to connect to device $mac..."
    
    if timeout 15 bluetoothctl connect "$mac" > /dev/null 2>&1; then
        log "INFO" "Successfully connected to $mac"
        return 0
    else
        log "WARN" "Failed to connect to $mac"
        return 1
    fi
}

# Ensure device is properly set up (paired and trusted)
ensure_device_setup() {
    local mac="$1"
    
    log "INFO" "Checking device setup for $mac..."
    
    # Check if paired
    if ! is_paired "$mac"; then
        log "INFO" "Device not paired. Attempting to pair..."
        if ! pair_device "$mac"; then
            log "ERROR" "Failed to pair device. Cannot continue."
            return 1
        fi
    else
        log "INFO" "Device is already paired"
    fi
    
    # Check if trusted
    if ! is_trusted "$mac"; then
        log "INFO" "Device not trusted. Attempting to trust..."
        if ! trust_device "$mac"; then
            log "ERROR" "Failed to trust device"
            return 1
        fi
    else
        log "INFO" "Device is already trusted"
    fi
    
    return 0
}

# Main monitoring loop
monitor_connection() {
    local mac="$1"
    local check_interval=30  # Check every 30 seconds
    local reconnect_attempts=0
    local max_reconnect_attempts=5
    local max_recconnect_reached_reconnect_delay=120

    log "INFO" "Starting connection monitoring for $mac (check interval: ${check_interval}s)"
    
    while true; do
        if is_connected "$mac"; then
            log "INFO" "Device $mac is connected"
            reconnect_attempts=0
        else
            log "WARN" "Device $mac is not connected"
            
            # Ensure device is still paired and trusted
            if ! ensure_device_setup "$mac"; then
                log "ERROR" "Device setup failed. Waiting before retry..."
                sleep 60
                continue
            fi
            
            # Attempt to connect
            if connect_device "$mac"; then
                log "INFO" "Reconnection successful"
                reconnect_attempts=0
            else
                reconnect_attempts=$((reconnect_attempts + 1))
                log "WARN" "Reconnection attempt $reconnect_attempts failed"
                
                if [ $reconnect_attempts -ge $max_reconnect_attempts ]; then
                    log "ERROR" "Max reconnection attempts reached. Waiting longer before retry..."
                    sleep $max_recconnect_reached_reconnect_delay 
                    reconnect_attempts=0
                fi
            fi
        fi
        
        sleep $check_interval
    done
}

# Main function
main() {
    if [ ! -d "$LOG_DIR" ]; then
        # Directory does not exist, so create it
        mkdir "$LOG_DIR"
    fi

    # Create log file if it doesn't exist
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi

    log "INFO" "Starting Bluetooth Connection Manager"
    
    # Check if already running
    check_if_running
    
    # Load configuration
    load_config
    
    # Ensure bluetooth service is running
    if ! systemctl is-active --quiet bluetooth; then
        log "ERROR" "Bluetooth service is not running. Please start it with: sudo systemctl start bluetooth"
        exit 1
    fi
    
    # Initial device setup
    if ! ensure_device_setup "$MAC_ADDRESS"; then
        log "ERROR" "Initial device setup failed. Exiting."
        exit 1
    fi
    
    # Start monitoring
    monitor_connection "$MAC_ADDRESS"
}

# Check if running with required privileges
if [ "$EUID" -eq 0 ]; then
    log "WARN" "Running as root. This may not be necessary."
fi

# Check if bluetoothctl is available
if ! command -v bluetoothctl > /dev/null 2>&1; then
    log "ERROR" "bluetoothctl not found. Please install bluez package."
    exit 1
fi

# Run main function
main "$@"

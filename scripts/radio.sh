#!/bin/bash

# WAMU Radio Stream Player (Shell Script Version)
# Plays https://wamu.cdnstream1.com/wamu.mp3 in the background
# Shell script equivalent of radio.py

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
STREAM_URL="https://wamu.cdnstream1.com/wamu.mp3"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="radio.log"

# Global variables
player_process_pid=""

# Logging function
log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') - radio - [$level] - $*" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "INFO" "Cleaning up..."
    
    if [ -n "$player_process_pid" ] && kill -0 "$player_process_pid" 2>/dev/null; then
        log "INFO" "Terminating audio player (PID: $player_process_pid)..."
        kill -TERM "$player_process_pid" 2>/dev/null || true
        
        # Wait up to 5 seconds for graceful termination
        local count=0
        while [ $count -lt 5 ] && kill -0 "$player_process_pid" 2>/dev/null; do
            sleep 1
            count=$((count + 1))
        done
        
        # Force kill if still running
        if kill -0 "$player_process_pid" 2>/dev/null; then
            log "WARNING" "Player didn't terminate gracefully, killing..."
            kill -KILL "$player_process_pid" 2>/dev/null || true
        fi
    fi
    
    log "INFO" "WAMU player stopped."
    exit $exit_code
}

# Signal handlers
signal_handler() {
    local signum="$1"
    log "INFO" "Received signal $signum. Shutting down gracefully..."
    cleanup
}

# Set up signal handlers
trap 'signal_handler SIGTERM' TERM
trap 'signal_handler SIGINT' INT
trap cleanup EXIT

# Check if another instance is already running
is_already_running() {
    local script_name="$1"
    
    if [ -z "$script_name" ]; then
        return 1
    fi
    
    # Get current process PID
    local current_pid=$$
    
    # Look for other instances
    local other_pids
    if other_pids=$(pgrep -f "$script_name" 2>/dev/null); then
        # Filter out current process
        local filtered_pids=""
        for pid in $other_pids; do
            if [ "$pid" != "$current_pid" ]; then
                filtered_pids="$filtered_pids $pid"
            fi
        done
        
        if [ -n "$filtered_pids" ]; then
            log "INFO" "Another instance already running (PID:$filtered_pids). Exiting."
            return 0
        fi
    fi
    
    return 1
}

# Find available audio player
find_audio_player() {
    local players=(
        "mpv --no-video --volume=80"
        "mpg123"
        "vlc --intf dummy --no-video"
        "mplayer -nocache"
        "ffplay -nodisp -autoexit"
    )
    
    local player_names=(
        "mpv"
        "mpg123"
        "vlc"
        "mplayer"
        "ffplay"
    )
    
    for i in "${!players[@]}"; do
        local cmd_base="${players[$i]%% *}"  # Get first word (command name)
        local full_cmd="${players[$i]}"
        local name="${player_names[$i]}"
        
        if command -v "$cmd_base" >/dev/null 2>&1; then
            log "INFO" "Found audio player: $name"
            echo "$full_cmd $STREAM_URL"
            return 0
        fi
    done
    
    return 1
}

# Play the WAMU stream
play_stream() {
    log "INFO" "Looking for suitable audio player..."
    
    # Find suitable audio player
    local player_cmd
    if ! player_cmd=$(find_audio_player); then
        log "ERROR" "No suitable audio player found!"
        log "ERROR" "Please install one of: mpv, mpg123, vlc, mplayer, or ffmpeg"
        return 1
    fi
    
    log "INFO" "Starting WAMU stream with command: $player_cmd"
    
    # Start the player process in background
    $player_cmd &
    player_process_pid=$!
    
    if [ -n "$player_process_pid" ]; then
        log "INFO" "WAMU stream started (PID: $player_process_pid)"
    else
        log "ERROR" "Failed to start audio player"
        return 1
    fi
    
    # Wait for the process to complete
    if wait "$player_process_pid"; then
        log "INFO" "Player finished normally"
        return 0
    else
        local exit_code=$?
        log "ERROR" "Player exited with code $exit_code"
        return 1
    fi
}

# Main function
main() {
    log "INFO" "WAMU Radio Stream Player starting..."
    
    # Check if already running
    if is_already_running "$SCRIPT_NAME"; then
        exit 0
    fi
    
    # Play the stream
    if play_stream; then
        log "INFO" "WAMU player finished successfully"
    else
        log "ERROR" "Failed to play stream"
        exit 1
    fi
}

# Check if required commands are available
if ! command -v pgrep >/dev/null 2>&1; then
    echo "Error: pgrep command not found. Please install procps package."
    exit 1
fi

# Run main function
main "$@"

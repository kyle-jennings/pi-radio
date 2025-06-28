#!/bin/bash

# Deploy script for pi-radio project
# Copies files to Raspberry Pi server excluding .git and .gitignore

set -e  # Exit on any error

# Configuration
LOCAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration from .env file
load_config() {
    local env_file="$LOCAL_PATH/.env"
    
    if [ ! -f "$env_file" ]; then
        log_error ".env file not found in $LOCAL_PATH"
        log_error "Please create a .env file with SERVER_USER and SERVER_HOST variables"
        log_error "Example:"
        log_error "  SERVER_USER=pi"
        log_error "  SERVER_HOST=192.168.0.113"
        exit 1
    fi
    
    # Source the .env file
    source "$env_file"
    
    # Check if SERVER_USER is set
    if [ -z "${SERVER_USER:-}" ]; then
        log_error "SERVER_USER not set in .env file"
        log_error "Please add SERVER_USER=your_username to .env"
        exit 1
    fi
    
    # Check if SERVER_HOST is set
    if [ -z "${SERVER_HOST:-}" ]; then
        log_error "SERVER_HOST not set in .env file" 
        log_error "Please add SERVER_HOST=your_server_ip to .env"
        exit 1
    fi
    
    # Set default SERVER_PATH if not provided
    if [ -z "${SERVER_PATH:-}" ]; then
        SERVER_PATH="/home/$SERVER_USER/pi-radio"
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    local color="$2"
    shift 2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level]${NC} $*"
}

log_info() {
    log "INFO" "$BLUE" "$@"
}

log_success() {
    log "SUCCESS" "$GREEN" "$@"
}

log_warning() {
    log "WARNING" "$YELLOW" "$@"
}

log_error() {
    log "ERROR" "$RED" "$@"
}

# Check if rsync is available
check_dependencies() {
    if ! command -v rsync >/dev/null 2>&1; then
        log_error "rsync is not installed. Please install it first:"
        log_error "  macOS: brew install rsync"
        log_error "  Ubuntu/Debian: sudo apt-get install rsync"
        exit 1
    fi
    
    if ! command -v ssh >/dev/null 2>&1; then
        log_error "ssh is not installed. Please install openssh-client."
        exit 1
    fi
}

# Test connection to server
test_connection() {
    log_info "Testing connection to $SERVER_USER@$SERVER_HOST..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$SERVER_USER@$SERVER_HOST" exit 2>/dev/null; then
        log_success "Connection successful"
        return 0
    else
        log_warning "SSH key authentication failed. You may need to enter password during transfer."
        return 1
    fi
}

# Create destination directory on server
create_destination() {
    log_info "Creating destination directory on server..."
    
    ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_PATH" || {
        log_error "Failed to create destination directory"
        exit 1
    }
    
    log_success "Destination directory ready"
}

# Deploy files using rsync
deploy_files() {
    log_info "Starting file transfer..."
    log_info "Source: $LOCAL_PATH"
    log_info "Destination: $SERVER_USER@$SERVER_HOST:$SERVER_PATH"
    
    # rsync options:
    # -a: archive mode (preserves permissions, timestamps, etc.)
    # -v: verbose
    # -z: compress during transfer
    # -h: human-readable progress
    # --progress: show progress
    # --delete: delete files on destination that don't exist in source
    # --exclude: exclude specified files/directories
    
    local rsync_options=(
        -avzh
        --progress
        --delete
        --exclude='.git/'
        --exclude='.gitignore'
        --exclude='*.pyc'
        --exclude='__pycache__/'
        --exclude='.DS_Store'
        --exclude='*.log'
        --exclude='.env'
        --exclude='node_modules/'
        --exclude='.vscode/'
        --exclude='*.tmp'
        --exclude='*.temp'
    )
    
    if rsync "${rsync_options[@]}" "$LOCAL_PATH/" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"; then
        log_success "File transfer completed successfully"
    else
        log_error "File transfer failed"
        exit 1
    fi
}

# Set proper permissions on server
set_permissions() {
    log_info "Setting proper permissions on server..."
    
    ssh "$SERVER_USER@$SERVER_HOST" "
        cd $SERVER_PATH && 
        chmod +x *.sh 2>/dev/null || true &&
        chmod +x *.py 2>/dev/null || true &&
        chmod +x scripts/*.sh 2>/dev/null || true &&
        find . -name '*.py' -exec chmod +x {} \; 2>/dev/null || true
    " || {
        log_warning "Some permission changes may have failed (this is usually not critical)"
    }
    
    log_success "Permissions set"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    local remote_files
    remote_files=$(ssh "$SERVER_USER@$SERVER_HOST" "find $SERVER_PATH -type f | wc -l" 2>/dev/null) || {
        log_error "Failed to verify deployment"
        return 1
    }
    
    log_success "Deployment verified: $remote_files files transferred"
}

# Show deployment summary
show_summary() {
    log_info "Deployment Summary:"
    echo "  Server: $SERVER_USER@$SERVER_HOST"
    echo "  Path: $SERVER_PATH"
    echo "  Excluded: .git/, .gitignore, *.pyc, __pycache__/, .DS_Store, *.log, .env"
    echo ""
    log_info "Next steps on the server:"
    echo "  1. ssh $SERVER_USER@$SERVER_HOST"
    echo "  2. cd $SERVER_PATH"
    echo "  3. cp .env.sample .env  # Edit with your settings"
    echo "  4. Install systemd services (see scripts/README.md)"
}

# Main function
main() {
    echo "============================================"
    echo "         Pi-Radio Deployment Script        "
    echo "============================================"
    echo
    
    load_config
    check_dependencies
    test_connection
    create_destination
    deploy_files
    set_permissions
    verify_deployment
    
    echo
    echo "============================================"
    log_success "Deployment completed successfully!"
    echo "============================================"
    echo
    show_summary
}

# Handle interruption
cleanup() {
    log_warning "Deployment interrupted"
    exit 130
}

trap cleanup INT TERM

# Check if we're in the right directory
# if [ ! -f "radio.py" ] || [ ! -f "play-wamu.sh" ]; then
#     log_error "This script must be run from the pi-radio project root directory"
#     log_error "Current directory: $(pwd)"
#     exit 1
# fi

# Run main function
main "$@"

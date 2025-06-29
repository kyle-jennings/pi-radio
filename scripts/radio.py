#!/usr/bin/env python3

"""
WAMU Radio Stream Player (Python Version)
Plays https://wamu.cdnstream1.com/wamu.mp3 in the background
"""

import os
import sys
import subprocess
import time
import signal
import logging

from pathlib import Path

# Import our custom logging utilities
from utils.logger_utils import setup_logging, get_logger

# Configuration
STREAM_URL = "https://wamu.cdnstream1.com/wamu.mp3"
SCRIPT_NAME = os.path.basename(__file__)

# Global variables
logger = None
player_process = None

def is_already_running(script_name):
    """Check if another instance of this script is already running"""
    if script_name is None:
        return False
        
    try:
        # Get current process PID
        current_pid = os.getpid()
        
        # Look for other instances
        result = subprocess.run(
            ['pgrep', '-f', script_name],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            pids = [int(pid.strip()) for pid in result.stdout.strip().split('\n') if pid.strip()]
            # Filter out current process
            other_pids = [pid for pid in pids if pid != current_pid]
            
            if other_pids:
                if logger:
                    logger.info(f"Another instance already running (PID: {other_pids}). Exiting.")
                return True
                
    except Exception as e:
        if logger:
            logger.warning(f"Could not check for running instances: {e}")
        return False
    
    return False

def signal_handler(signum, frame):
    """Handle termination signals gracefully"""
    global player_process
    logger.info(f"Received signal {signum}. Shutting down gracefully...")
    
    if player_process and player_process.poll() is None:
        logger.info("Terminating audio player...")
        player_process.terminate()
        try:
            player_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            logger.warning("Player didn't terminate gracefully, killing...")
            player_process.kill()
    
    logger.info("WAMU player stopped.")
    sys.exit(0)

def find_audio_player():
    """Find available audio player and return command"""
    players = [
        (['mplayer', '-nocache'], 'mplayer'),
        (['mpv', '--no-video', '--volume=80'], 'mpv'),
        (['mpg123'], 'mpg123'),
        (['vlc', '--intf', 'dummy', '--no-video'], 'vlc'),
        (['ffplay', '-nodisp', '-autoexit'], 'ffplay')
    ]
    
    for cmd_base, name in players:
        try:
            # Check if command exists
            subprocess.run(['which', cmd_base[0]], 
                         check=True, 
                         capture_output=True)
            logger.info(f"Found audio player: {name}")
            return cmd_base + [STREAM_URL]
        except subprocess.CalledProcessError:
            continue
    
    return None

def play_stream():
    """Play the WAMU stream"""
    global player_process
    
    # Find suitable audio player
    player_cmd = find_audio_player()
    if not player_cmd:
        logger.error("No suitable audio player found!")
        logger.error("Please install one of: mpv, mpg123, vlc, mplayer, or ffmpeg")
        return False
    
    try:
        logger.info(f"Starting WAMU stream with command: {' '.join(player_cmd)}")
        
        # Start the player process
        player_process = subprocess.Popen(
            player_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid  # Create new process group
        )
        
        logger.info(f"WAMU stream started (PID: {player_process.pid})")
        
        # Wait for the process to complete
        while player_process.poll() is None:
            time.sleep(1)
        
        # Check exit status
        if player_process.returncode != 0:
            stderr_output = player_process.stderr.read().decode('utf-8', errors='ignore')
            logger.error(f"Player exited with code {player_process.returncode}")
            if stderr_output:
                logger.error(f"Player error: {stderr_output}")
            return False
        
        logger.info("Player finished normally")
        return True
        
    except Exception as e:
        logger.error(f"Error starting player: {e}")
        return False

def main():
    """Main function"""
    global logger
    
    # Initialize logging with auto-detection
    logger = setup_logging(
        log_level=logging.INFO,
        console_output=True,
        file_output=True
    )

    logger.info("WAMU Radio Stream Player starting...")
    
    # Set up signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Check if already running
    if is_already_running(SCRIPT_NAME):
        logger.info(f"!! Another instance already running). Exiting.")
        sys.exit(0)
    

    # Play the stream
    success = play_stream()
    
    if not success:
        logger.error("Failed to play stream")
        sys.exit(1)
    
    logger.info("WAMU player finished")

if __name__ == "__main__":
    main()

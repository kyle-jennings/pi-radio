# WAMU Radio Stream Player

A shell script designed to automatically play the WAMU NPR radio stream on a Raspberry Pi. The script prevents multiple instances from running simultaneously and includes comprehensive error handling.

## Features

- Plays WAMU NPR radio stream (`https://wamu.cdnstream1.com/wamu.mp3`)
- Prevents duplicate instances from running
- Supports multiple audio players with automatic fallback
- Comprehensive error handling and graceful exits
- Designed for Raspberry Pi (Debian-based systems)

## Manual Usage

```bash
# Run the script
$ python3 ./scripts/radio.py

# Stop the stream (Ctrl+C)
# The script will exit gracefully
```

## Deployment
```
$ rsync -avz --progress --exclude='.git/' --exclude='.gitignore' --exclude='*.pyc' --exclude='__pycache__/' --exclude='.DS_Store' --exclude='*.log'  ./pi-radio pi@192.168.0.113:/home/pi/
```

## Stopping the Service

### Temporary stop:
```bash
pkill -f "wamu.mp3"
# OR
pkill -f "radio.py"
```


## System Requirements

- Raspberry Pi (any model) or Debian-based Linux system
- Internet connection
- Audio output (speakers, headphones, or audio HAT)
- One of the supported audio players (see Required Software section)

## License

This project is open source. Feel free to modify and distribute as needed.

# WAMU Radio Stream Player

A shell script designed to automatically play the WAMU NPR radio stream on a Raspberry Pi. The script prevents multiple instances from running simultaneously and includes comprehensive error handling.

## Features

- Plays WAMU NPR radio stream (`https://wamu.cdnstream1.com/wamu.mp3`)
- Prevents duplicate instances from running
- Supports multiple audio players with automatic fallback
- Comprehensive error handling and graceful exits
- Designed for Raspberry Pi (Debian-based systems)

## Required Software

The script requires at least one of the following audio players to be installed:

### Recommended (in order of preference):

1. **mpv** (Recommended)
   ```bash
   sudo apt update
   sudo apt install mpv
   ```

2. **mpg123** (Lightweight, ideal for Raspberry Pi)
   ```bash
   sudo apt update
   sudo apt install mpg123
   ```

3. **VLC** (Full-featured media player)
   ```bash
   sudo apt update
   sudo apt install vlc
   ```

4. **mplayer** (Classic media player)
   ```bash
   sudo apt update
   sudo apt install mplayer
   ```

5. **ffplay** (Part of ffmpeg)
   ```bash
   sudo apt update
   sudo apt install ffmpeg
   ```

### Quick Install (installs mpg123 - recommended for Pi):
```bash
sudo apt update && sudo apt install mpg123 pulseaudio pulseaudio-module-bluetooth
```

## Installation

1. **Clone or download the script:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/pi-radio/main/play-wamu.sh
   # OR copy the play-wamu.sh file to your Raspberry Pi
   ```

2. **Make the script executable:**
   ```bash
   chmod +x play-wamu.sh
   ```

3. **Test the script:**
   ```bash
   ./play-wamu.sh
   ```

## Manual Usage

```bash
# Run the script
./play-wamu.sh

# Stop the stream (Ctrl+C)
# The script will exit gracefully
```

## Automatic Startup (Cron)

To ensure the WAMU stream is always playing and automatically restarts if it stops, set up a cron job that runs every minute.

### Setup Instructions:

1. **Open the crontab editor:**
   ```bash
   crontab -e
   ```

2. **Add the following line to run the script every minute:**
   ```bash
   * * * * * /full/path/to/play-wamu.sh >/dev/null 2>&1
   ```

   **Example** (replace with your actual path):
   ```bash
   * * * * * /home/pi/pi-radio/play-wamu.sh >/dev/null 2>&1
   ```

3. **Save and exit the editor**
   - For nano: `Ctrl+X`, then `Y`, then `Enter`
   - For vim: `Esc`, then `:wq`, then `Enter`

4. **Verify the cron job is installed:**
   ```bash
   crontab -l
   ```

### Alternative: Run at boot only

If you prefer to only start the stream at boot (without the every-minute check), use this cron entry instead:

```bash
@reboot /full/path/to/play-wamu.sh >/dev/null 2>&1
```

### Cron Job Explanation:

- `* * * * *`: Run every minute
- `/full/path/to/play-wamu.sh`: Full path to your script
- `>/dev/null 2>&1`: Suppress output (since the script handles its own logging)

The script's built-in duplicate detection ensures that even if cron runs it every minute, only one instance will actually play the stream.

## Troubleshooting

### Check if the script is running:
```bash
ps aux | grep -E "(play-wamu|wamu.mp3)" | grep -v grep
```

### Check cron logs:
```bash
grep CRON /var/log/syslog | tail -10
```

### Test audio output:
```bash
# Test with a simple beep
speaker-test -t sine -f 1000 -l 1

# Or test with mpg123 directly
mpg123 https://wamu.cdnstream1.com/wamu.mp3
```

### Common Issues:

1. **No audio output:**
   - Check audio configuration: `sudo raspi-config` → Advanced Options → Audio
   - Test with: `aplay /usr/share/sounds/alsa/Front_Left.wav`

2. **Script not running automatically:**
   - Verify cron service is running: `sudo systemctl status cron`
   - Check crontab: `crontab -l`
   - Use absolute paths in cron jobs

3. **Permission denied:**
   - Make script executable: `chmod +x play-wamu.sh`
   - Check file ownership: `ls -la play-wamu.sh`

## Stopping the Service

### Temporary stop:
```bash
pkill -f "wamu.mp3"
# OR
pkill -f "play-wamu"
```

### Disable automatic startup:
```bash
crontab -e
# Comment out or delete the line with play-wamu.sh
```

## System Requirements

- Raspberry Pi (any model) or Debian-based Linux system
- Internet connection
- Audio output (speakers, headphones, or audio HAT)
- One of the supported audio players (see Required Software section)

## License

This project is open source. Feel free to modify and distribute as needed.

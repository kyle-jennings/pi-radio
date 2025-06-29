# Radio Player Service

The `radio.service` systemd unit file manages the WAMU radio stream player for continuous audio playback.

## Installation and Usage

### 1. Install the Service

Copy the service file to systemd directory and reload:

```bash
sudo cp /home/pi/pi-radio/scripts/radio.service /etc/systemd/system/
sudo systemctl daemon-reload
```

### 2. Enable and Start the Service

Enable the service to start automatically on boot and start it immediately:

```bash
sudo systemctl enable radio.service
sudo systemctl start radio.service
```

### 3. Check Service Status

Verify the service is running correctly:

```bash
sudo systemctl status radio.service
```

Expected output should show:
- `Active: active (running)`
- Recent log entries showing radio stream activity

### 4. View Service Logs

Monitor real-time logs:
```bash
sudo journalctl -u radio.service -f
```

View recent logs:
```bash
sudo journalctl -u radio.service --since "1 hour ago"
```

View logs from last boot:
```bash
sudo journalctl -u radio.service -b
```

### 5. Service Control Commands

**Stop the service:**
```bash
sudo systemctl stop radio.service
```

**Restart the service:**
```bash
sudo systemctl restart radio.service
```

**Disable the service (prevent auto-start on boot):**
```bash
sudo systemctl disable radio.service
```

**Re-enable the service:**
```bash
sudo systemctl enable radio.service
```

### Service Features

- **Auto-restart**: Automatically restarts if the script fails or exits
- **Network dependency**: Waits for network connectivity before starting
- **Audio system integration**: Waits for sound system to be available
- **Security hardening**: Runs with minimal privileges
- **Comprehensive logging**: Integrates with systemd journal
- **Rate limiting**: Prevents rapid restart cycles (max 5 restarts in 5 minutes)
- **Duplicate prevention**: Built-in script logic prevents multiple instances

### Prerequisites

#### Required Audio Players
The service requires at least one of these audio players to be installed:

```bash
# Install mpv (recommended)
sudo apt update && sudo apt install mpv

# Or install mpg123 (lightweight)
sudo apt update && sudo apt install mpg123

# Or install VLC
sudo apt update && sudo apt install vlc

# Or install mplayer
sudo apt update && sudo apt install mplayer

# Or install ffmpeg (includes ffplay)
sudo apt update && sudo apt install ffmpeg
```

#### Audio System Configuration
Ensure audio output is properly configured:

```bash
# Check available audio devices
aplay -l

# Test audio output
speaker-test -t sine -f 1000 -l 1

# Configure audio output (if needed)
sudo raspi-config
# Navigate to: Advanced Options → Audio
```

### Troubleshooting

#### Service Won't Start
1. Check if the radio.py script exists and dependencies are met:
   ```bash
   ls -la /home/pi/pi-radio/radio.py
   python3 /home/pi/pi-radio/radio.py --help
   ```

2. Verify audio player is installed:
   ```bash
   which mpv || which mpg123 || which vlc || which mplayer || which ffplay
   ```

3. Check network connectivity:
   ```bash
   ping -c 3 wamu.cdnstream1.com
   curl -I https://wamu.cdnstream1.com/wamu.mp3
   ```

#### Service Keeps Restarting
1. Check the service logs for error messages:
   ```bash
   sudo journalctl -u radio.service --since "10 minutes ago"
   ```

2. Common issues:
   - No audio player installed
   - Network connectivity problems
   - Audio system not configured
   - Stream URL inaccessible
   - Permission issues with audio devices

#### No Audio Output
1. Check audio configuration:
   ```bash
   # List audio devices
   aplay -l
   
   # Check volume levels
   alsamixer
   
   # Test audio
   aplay /usr/share/sounds/alsa/Front_Left.wav
   ```

2. Check if audio group membership:
   ```bash
   groups pi | grep audio
   # If not in audio group, add:
   sudo usermod -a -G audio pi
   ```

#### Check Service Dependencies
```bash
# Check network status
sudo systemctl status network-online.target

# Check audio system
sudo systemctl status sound.target

# Test stream manually
curl -I https://wamu.cdnstream1.com/wamu.mp3
```

### Configuration

The service automatically detects and uses available audio players in this order of preference:
1. **mpv** (recommended for streaming)
2. **mpg123** (lightweight, good for Raspberry Pi)
3. **vlc** (full-featured media player)
4. **mplayer** (classic media player)
5. **ffplay** (part of ffmpeg)

### Stream Information

- **Stream URL**: https://wamu.cdnstream1.com/wamu.mp3
- **Station**: WAMU 88.5 FM (American University Radio)
- **Format**: MP3 stream
- **Content**: NPR programming and local content

### Log Files

The service creates logs in two locations:

1. **Systemd Journal**: `journalctl -u radio.service`
2. **Local Log File**: `/var/log/radio.log` (or fallback locations)

### Service Restart Policy

- **Restart**: Always (on any exit)
- **Restart Delay**: 15 seconds (allows network/audio recovery)
- **Rate Limiting**: Maximum 5 restarts in 5 minutes
- **Timeout**: 30 seconds for graceful shutdown

### Performance Considerations

- **CPU Usage**: Minimal (audio decoding only)
- **Memory Usage**: Low (typically 10-50MB depending on player)
- **Network Usage**: Continuous streaming (~128kbps)
- **Audio Latency**: Real-time streaming with minimal delay

### Security

The service runs with these security measures:
- Non-root user (`pi`)
- No new privileges
- Protected home and system directories
- Limited write access to necessary paths only
- Proper signal handling for graceful shutdown

### Integration with Other Services

This service can run alongside:
- `bluetooth-manager.service` (for Bluetooth audio output)
- Other audio services (with proper configuration)
- Monitoring services

Note: Only one instance of the radio player will run at a time due to built-in duplicate detection.

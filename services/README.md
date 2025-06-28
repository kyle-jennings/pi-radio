# Scripts Directory

This directory contains systemd service files and scripts for managing the pi-radio system components.

## Bluetooth Manager Service

The `bluetooth-manager.service` systemd unit file manages the Bluetooth connection monitoring and automatic reconnection functionality.

### Installation and Usage

#### 1. Install the Service

Copy the service file to systemd directory and reload:

```bash
sudo cp /home/pi/pi-radio/scripts/bluetooth-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
```

#### 2. Enable and Start the Service

Enable the service to start automatically on boot and start it immediately:

```bash
sudo systemctl enable bluetooth-manager.service
sudo systemctl start bluetooth-manager.service
```

#### 3. Check Service Status

Verify the service is running correctly:

```bash
sudo systemctl status bluetooth-manager.service
```

Expected output should show:
- `Active: active (running)`
- Recent log entries showing Bluetooth monitoring activity

#### 4. View Service Logs

Monitor real-time logs:
```bash
sudo journalctl -u bluetooth-manager.service -f
```

View recent logs:
```bash
sudo journalctl -u bluetooth-manager.service --since "1 hour ago"
```

View logs from last boot:
```bash
sudo journalctl -u bluetooth-manager.service -b
```

#### 5. Service Control Commands

**Stop the service:**
```bash
sudo systemctl stop bluetooth-manager.service
```

**Restart the service:**
```bash
sudo systemctl restart bluetooth-manager.service
```

**Disable the service (prevent auto-start on boot):**
```bash
sudo systemctl disable bluetooth-manager.service
```

**Re-enable the service:**
```bash
sudo systemctl enable bluetooth-manager.service
```

### Service Features

- **Auto-restart**: Automatically restarts if the script fails or exits
- **Dependency management**: Waits for Bluetooth service to be available
- **Security hardening**: Runs with minimal privileges
- **Comprehensive logging**: Integrates with systemd journal
- **Rate limiting**: Prevents rapid restart cycles (max 5 restarts in 5 minutes)

### Troubleshooting

#### Service Won't Start
1. Check if the bluetooth-manager.sh script exists and is executable:
   ```bash
   ls -la /home/pi/pi-radio/bluetooth-manager.sh
   chmod +x /home/pi/pi-radio/bluetooth-manager.sh
   ```

2. Verify the .env file exists with MAC_ADDRESS:
   ```bash
   cat /home/pi/pi-radio/.env
   ```

3. Check Bluetooth service status:
   ```bash
   sudo systemctl status bluetooth.service
   ```

#### Service Keeps Restarting
1. Check the service logs for error messages:
   ```bash
   sudo journalctl -u bluetooth-manager.service --since "10 minutes ago"
   ```

2. Common issues:
   - Missing or invalid MAC address in .env file
   - Bluetooth device not in range or not discoverable
   - Bluetooth service not running
   - Permission issues

#### Check Service Dependencies
```bash
# Check if Bluetooth service is running
sudo systemctl status bluetooth.service

# Check if network is available
ping -c 1 google.com
```

### Configuration

The service reads configuration from `/home/pi/pi-radio/.env`. Ensure this file contains:

```
MAC_ADDRESS=AA:BB:CC:DD:EE:FF
```

Replace `AA:BB:CC:DD:EE:FF` with your actual Bluetooth device MAC address.

### Log Files

The service creates logs in two locations:

1. **Systemd Journal**: `journalctl -u bluetooth-manager.service`
2. **Local Log File**: `/home/pi/pi-radio/bluetooth-manager.log`

### Service Restart Policy

- **Restart**: Always (on any exit)
- **Restart Delay**: 10 seconds
- **Rate Limiting**: Maximum 5 restarts in 5 minutes
- **Timeout**: 30 seconds for graceful shutdown

### Security

The service runs with these security measures:
- Non-root user (`pi`)
- No new privileges
- Protected home and system directories
- Limited write access to necessary paths only

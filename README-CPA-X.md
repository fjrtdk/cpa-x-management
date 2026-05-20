# CPA-X CLI Management

This directory contains CLI tools for managing CPA-X (CLIProxyAPI) without a dashboard.

## Files

- `manage-cpa-x.sh` - Main management script for service operations
- `config.yaml` - CPA-X configuration template
- `backup.sh` - Automated backup and version control script

## manage-cpa-x.sh

Manages the `cli-proxy-api` systemd service.

### Usage

```bash
./manage-cpa-x.sh [command]
```

### Commands

| Command | Description |
|---------|-------------|
| `status` | Show current service status |
| `restart` | Restart the CPA-X service (requires sudo) |
| `logs` | Tail live service logs |

### Examples

```bash
# Check service status
./manage-cpa-x.sh status

# Restart service (will prompt for sudo password)
./manage-cpa-x.sh restart

# View logs in real-time
./manage-cpa-x.sh logs
```

### Requirements

- `systemd` service named `cli-proxy-api` must be installed and enabled
- `sudo` privileges required for restart operation
- User must be in `adm` or `systemd-journal` group to view logs without sudo

### Troubleshooting

**"Interactive authentication required" on restart**
- Ensure you have sudo privileges configured
- Use `sudo -v` to refresh your sudo timestamp before running

**"Unit cli-proxy-api.service not found"**
- The service is not installed. Install CPA-X first.

**"Failed to connect to bus: No such file or directory"**
- System is not running systemd. This tool requires systemd.

**Logs show "Permission denied"**
- Add your user to the `adm` or `systemd-journal` group:
  ```bash
  sudo usermod -aG systemd-journal $USER
  ```
  Log out and back in for group changes to take effect.

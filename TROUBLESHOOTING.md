# Troubleshooting Guide

## Common Issues and Solutions

### Container Not Found
**Error:** `Container 'qbittorrent' is NOT running`

**Solutions:**
1. Verify container name: `docker ps` and update `CONTAINER` variable
2. Check if container is actually running
3. Ensure the script runs after container startup

### NAT-PMP Failures
**Error:** `Failed to map port or retrieve mapped port`

**Common causes:**
1. **VPN doesn't support NAT-PMP** - Ensure your VPN provider supports NAT-PMP
2. **Wrong gateway IP** - Verify `WGTUNNEL` matches your WireGuard gateway
3. **Port already in use** - Try a different `LISTENING_PORT`
4. **VPN connection issues** - Check VPN connectivity

**Debugging steps:**
```bash
# Test NAT-PMP manually inside container
docker exec qbittorrent natpmpc -a 0 6881 tcp 1200 -g 10.2.0.1

# Check container network configuration
docker exec qbittorrent ip route
```

### libnatpmp Installation Fails
**Error:** `Failed to install libnatpmp in container`

**Solutions:**
1. Check container internet connectivity
2. Verify container uses Alpine Linux (for apk)
3. For other distros, install manually or modify script

### Log File Issues
**Problem:** Log file growing too large or not rotating

**Solutions:**
1. Adjust `LOG_RETENTION_DAY` value
2. Ensure `/var/log` is writable
3. Consider using `/tmp` for temporary storage

### Script Exits Immediately
**Problem:** Script stops with validation errors

**Check:**
1. Port numbers are valid (1-65535)
2. Interval is >= 10 seconds
3. All required variables are set

## Performance Optimization

### Reducing Resource Usage
- Increase `INTERVAL` for less frequent checks (60-300 seconds)
- Use `/tmp` for logs if RAM is limited
- Set shorter `LOG_RETENTION_DAY` value

### Network Optimization
- Ensure stable VPN connection
- Monitor for connection drops
- Consider redundant VPN configurations

## Advanced Configuration

### Environment Variables
You can set configuration via environment variables:
```bash
export CONTAINER="transmission"
export LISTENING_PORT="51413"
export WGTUNNEL="10.3.0.1"
./p2p-port-forward-script.sh
```

### Multiple Containers
For multiple torrent clients, run separate script instances:
```bash
# Copy script for each container
cp p2p-port-forward-script.sh qbit-forward.sh
cp p2p-port-forward-script.sh transmission-forward.sh

# Edit each with different configuration
# Run each separately
```

## Getting Help

1. Check logs: `tail -f /var/log/natpmp_forward.log`
2. Verify configuration matches your setup
3. Test components individually (Docker, VPN, NAT-PMP)
4. Search existing GitHub issues
5. Create new issue with full context and logs

## Useful Commands

```bash
# View live logs
tail -f /var/log/natpmp_forward.log

# Test container connectivity
docker exec qbittorrent ping -c 3 8.8.8.8

# Check VPN status
docker exec qbittorrent curl -s https://api.ipify.org

# Manual NAT-PMP test
docker exec qbittorrent natpmpc -a 0 6881 tcp 1200 -g 10.2.0.1

# View script processes
ps aux | grep natpmp
```
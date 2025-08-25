# Security Considerations

## Script Security

### File Permissions
Set appropriate permissions on the script:
```bash
chmod 750 p2p-port-forward-script.sh
chown root:root p2p-port-forward-script.sh
```

### Log Security
- Script logs to `/var/log` by default (RAM-based, cleared on reboot)
- Avoid logging to persistent storage to prevent filling disk
- Log rotation is automatic to prevent memory issues
- Consider using `/tmp` for truly temporary logs

### Container Security
- Script requires Docker access to inspect and exec into containers
- Only runs commands necessary for NAT-PMP functionality
- Uses `set -euo pipefail` for safer bash execution
- Validates input parameters to prevent injection

## VPN Security

### ProtonVPN Best Practices
- Use dedicated P2P servers only
- Enable NAT-PMP only when needed
- Regularly rotate WireGuard configurations
- Monitor connection logs for anomalies

### Network Isolation
- Torrent containers should only route through VPN
- Verify no traffic leaks outside VPN tunnel
- Test with tools like `curl ifconfig.me` inside container

## unRAID Security

### User Scripts Plugin
- Only install scripts from trusted sources
- Review script contents before execution
- Use User Scripts logging for audit trail
- Set scripts to run with minimal required privileges

### Docker Security
- Keep container images updated
- Use official images when possible
- Limit container capabilities and resources
- Monitor container network access

## Monitoring and Alerting

### What to Monitor
- Script execution status
- VPN connection health
- Unexpected port mapping failures
- Container restart frequency

### Log Analysis
```bash
# Check for errors in logs
grep -i error /var/log/natpmp_forward.log

# Monitor port mapping success rate
grep "mapped successfully" /var/log/natpmp_forward.log | wc -l

# Check for container issues
grep "NOT running" /var/log/natpmp_forward.log
```

## Incident Response

### If Script is Compromised
1. Stop the script immediately
2. Check system logs for unauthorized access
3. Rotate VPN credentials
4. Review container logs for suspicious activity
5. Update script from trusted source

### If VPN is Compromised
1. Disconnect VPN immediately
2. Check for traffic leaks
3. Rotate all VPN credentials
4. Monitor torrent client for direct connections
5. Re-establish secure VPN connection

## Security Updates

### Keep Updated
- Monitor this repository for security updates
- Update container images regularly
- Keep unRAID system updated
- Review VPN provider security advisories

### Reporting Security Issues
- Report security vulnerabilities privately via GitHub Security
- Include detailed description and reproduction steps
- Allow reasonable time for fix before public disclosure

## Risk Assessment

### Low Risk
- Script runs with necessary privileges only
- Network access is VPN-tunneled
- Logs contain minimal sensitive information

### Medium Risk
- Requires Docker access for container management
- VPN credentials stored in unRAID configuration
- Network port exposure through NAT-PMP

### Mitigation Strategies
- Regular security reviews of script changes
- Monitor for unauthorized script modifications
- Use dedicated VPN accounts for torrenting
- Implement network monitoring and alerting
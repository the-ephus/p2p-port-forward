#!/bin/bash

# p2p-port-forward - Automatic NAT-PMP port forwarding for unRAID torrent containers
# Licensed under GPL v3

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# CONFIGURATION
CONTAINER="${CONTAINER:-qbittorrent}" # exact name of your torrent container in unRAID
LISTENING_PORT="${LISTENING_PORT:-6881}" # port that your torrent client is expecting to listen on for p2p connections
WGTUNNEL="${WGTUNNEL:-10.2.0.1}" # wireguard local tunnel network pool, found in unRAID VPN manager. Copy this address and change the final octet to 1 instead of 0.
LOGFILE="${LOGFILE:-/var/log/natpmp_forward.log}" # /var/log will log to RAM, which is ideal. Avoid logging to the USB flash drive.
LOG_RETENTION_DAY="${LOG_RETENTION_DAY:-3}" # recommend 1-3 days so the log file does not grow endlessly
INTERVAL="${INTERVAL:-45}" # script loop frequency, in seconds

# Validate configuration
if [[ ! "$LISTENING_PORT" =~ ^[0-9]+$ ]] || [[ "$LISTENING_PORT" -lt 1 ]] || [[ "$LISTENING_PORT" -gt 65535 ]]; then
    echo "ERROR: LISTENING_PORT must be a valid port number (1-65535)" >&2
    exit 1
fi

if [[ ! "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -lt 10 ]]; then
    echo "ERROR: INTERVAL must be a number >= 10 seconds" >&2
    exit 1
fi

# Logging functions
log_info() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOGFILE"
}

log_error() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $message" | tee -a "$LOGFILE" >&2
}

log_debug() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $message" >> "$LOGFILE"
}

# Create log directory and file
mkdir -p "$(dirname "$LOGFILE")"

log_info "Starting p2p-port-forward script"
log_info "Configuration: Container=$CONTAINER, Port=$LISTENING_PORT, Gateway=$WGTUNNEL, Interval=${INTERVAL}s"

# Wait for container to initialize
log_info "Waiting 60 seconds for container to initialize..."
sleep 60

# Check if container is running before starting
if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
    log_error "Container '$CONTAINER' is NOT running. Exiting."
    exit 1
fi

log_info "Container '$CONTAINER' is running"

# Check/install libnatpmp once before loop
if ! docker exec "$CONTAINER" which natpmpc &>/dev/null; then
    log_info "natpmpc not found, installing in container '$CONTAINER'..."
    if ! docker exec "$CONTAINER" apk update; then
        log_error "Failed to update package list in container"
        exit 1
    fi
    if ! docker exec "$CONTAINER" apk add --no-cache libnatpmp; then
        log_error "Failed to install libnatpmp in container"
        exit 1
    fi
    log_info "Successfully installed libnatpmp"
else
    log_info "natpmpc is already available in container"
fi

while true; do
    # Rotate log if older than retention period
    if [[ -f "$LOGFILE" ]]; then
        FILE_AGE_DAYS=$(( ( $(date +%s) - $(stat -c %Y "$LOGFILE") ) / 86400 ))
        if (( FILE_AGE_DAYS >= LOG_RETENTION_DAY )); then
            log_info "Rotating log file (age: ${FILE_AGE_DAYS} days)"
            rm -f "$LOGFILE"
        fi
    fi

    DATE_LINE="===== $(date) ====="
    echo "$DATE_LINE"
    echo "$DATE_LINE" >> "$LOGFILE"

    # Check that container is still running in each loop
    if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
        log_error "Container '$CONTAINER' is NOT running."
        sleep "$INTERVAL"
        continue
    fi

    # Run natpmpc for TCP
    log_debug "Executing NAT-PMP request for TCP port $LISTENING_PORT"
    TCP_OUTPUT=$(docker exec "$CONTAINER" natpmpc -a 0 "$LISTENING_PORT" tcp 1200 -g "$WGTUNNEL" 2>&1)
    {
        echo "TCP Mapping Output:"
        echo "$TCP_OUTPUT"
        echo ""
    } >> "$LOGFILE"

    # Run natpmpc for UDP  
    log_debug "Executing NAT-PMP request for UDP port $LISTENING_PORT"
    UDP_OUTPUT=$(docker exec "$CONTAINER" natpmpc -a 0 "$LISTENING_PORT" udp 1200 -g "$WGTUNNEL" 2>&1)
    {
        echo "UDP Mapping Output:"
        echo "$UDP_OUTPUT"
        echo ""
    } >> "$LOGFILE"

    # Extract mapped port
    MAPPED_PORT=$(echo "$UDP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' | tail -n1)

    if [[ -z "$MAPPED_PORT" || ! "$MAPPED_PORT" =~ ^[0-9]+$ ]]; then
        log_error "Failed to map port or retrieve mapped port. Check natpmpc output above."
        echo "" >> "$LOGFILE"
    else
        log_info "VPN port mapped successfully: $MAPPED_PORT to $LISTENING_PORT"
        echo "" >> "$LOGFILE"
    fi

    sleep "$INTERVAL"
done

#!/bin/bash

# CONFIGURATION
CONTAINER="qbittorrent" # exact name of your torrent container in unRAID
LISTENING_PORT="6881" # port that your torrent client is expecting to listen on for p2p connections
WGTUNNEL="10.2.0.1" # wireguard local tunnel network pool, found in unRAID VPN manager. Copy this address and change the final octet to 1 instead of 0.
LOGFILE="/var/log/natpmp_forward.log" # /var/log will log to RAM, which is ideal. Avoid logging to the USB flash drive.
LOG_RETENTION_DAY=3 # recommend 1-3 days so the log file does not grow endlessly
INTERVAL=45 # script loop frequency, in seconds

# Create log directory and file
mkdir -p "$(dirname "$LOGFILE")"

# Wait for container to initialize
sleep 60

# Check if container is running before starting
if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
    echo "Container '$CONTAINER' is NOT running. Exiting." | tee -a "$LOGFILE"
    exit 1
fi

# Check/install libnatpmp once before loop
if ! docker exec "$CONTAINER" which natpmpc &>/dev/null; then
    echo "natpmpc not found, installing in container '$CONTAINER'..." | tee -a "$LOGFILE"
    docker exec "$CONTAINER" apk update
    
    # Try different package names and repositories for natpmpc
    INSTALL_SUCCESS=false
    
    # First try common package names in main repository
    for package in libnatpmp natpmpc libnatpmp-dev natpmp; do
        echo "Trying to install package: $package" | tee -a "$LOGFILE"
        if docker exec "$CONTAINER" apk add --no-cache "$package" 2>&1 | tee -a "$LOGFILE"; then
            if docker exec "$CONTAINER" which natpmpc &>/dev/null; then
                echo "Successfully installed natpmpc via package: $package" | tee -a "$LOGFILE"
                INSTALL_SUCCESS=true
                break
            else
                echo "Package $package installed but natpmpc still not found" | tee -a "$LOGFILE"
                docker exec "$CONTAINER" apk del "$package" &>/dev/null
            fi
        else
            echo "Package $package not available or failed to install" | tee -a "$LOGFILE"
        fi
    done
    
    # If main packages fail, try enabling testing repository
    if [ "$INSTALL_SUCCESS" = false ]; then
        echo "Trying testing repository..." | tee -a "$LOGFILE"
        docker exec "$CONTAINER" sh -c 'echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories'
        docker exec "$CONTAINER" apk update
        
        for package in libnatpmp natpmpc; do
            echo "Trying to install from testing repo: $package" | tee -a "$LOGFILE"
            if docker exec "$CONTAINER" apk add --no-cache "$package" 2>&1 | tee -a "$LOGFILE"; then
                if docker exec "$CONTAINER" which natpmpc &>/dev/null; then
                    echo "Successfully installed natpmpc from testing repo via package: $package" | tee -a "$LOGFILE"
                    INSTALL_SUCCESS=true
                    break
                else
                    echo "Package $package installed from testing but natpmpc still not found" | tee -a "$LOGFILE"
                    docker exec "$CONTAINER" apk del "$package" &>/dev/null
                fi
            else
                echo "Package $package not available in testing repository" | tee -a "$LOGFILE"
            fi
        done
    fi
    
    # Final check and error if still not found
    if [ "$INSTALL_SUCCESS" = false ]; then
        echo "ERROR: Unable to install natpmpc. Please install it manually in the container." | tee -a "$LOGFILE"
        echo "You can try: docker exec $CONTAINER sh" | tee -a "$LOGFILE"
        echo "Then manually compile from source: https://github.com/miniupnp/libnatpmp" | tee -a "$LOGFILE"
        exit 1
    fi
fi

while true; do

    # Rotate log if older than retention period
    if [[ -f "$LOGFILE" ]]; then
        FILE_AGE_DAYS=$(( ( $(date +%s) - $(stat -c %Y "$LOGFILE") ) / 86400 ))
        if (( FILE_AGE_DAYS >= LOG_RETENTION_DAY )); then
            rm -f "$LOGFILE"
        fi
    fi

    DATE_LINE="===== $(date) ====="
    echo "$DATE_LINE"
    echo "$DATE_LINE" >> "$LOGFILE"

    # Check that container is still running in each loop
    if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
        echo "Container '$CONTAINER' is NOT running." | tee -a "$LOGFILE"
        sleep "$INTERVAL"
        continue
    fi

    # Run natpmpc for TCP
    TCP_OUTPUT=$(docker exec "$CONTAINER" natpmpc -a 0 "$LISTENING_PORT" tcp 1200 -g "$WGTUNNEL" 2>&1)
    echo "TCP Mapping Output:" >> "$LOGFILE"
    echo "$TCP_OUTPUT" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    # Run natpmpc for UDP
    UDP_OUTPUT=$(docker exec "$CONTAINER" natpmpc -a 0 "$LISTENING_PORT" udp 1200 -g "$WGTUNNEL" 2>&1)
    echo "UDP Mapping Output:" >> "$LOGFILE"
    echo "$UDP_OUTPUT" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    # Extract mapped port
    MAPPED_PORT=$(echo "$UDP_OUTPUT" | grep -oP 'Mapped public port \K[0-9]+' | tail -n1)

    if [[ -z "$MAPPED_PORT" || ! "$MAPPED_PORT" =~ ^[0-9]+$ ]]; then
        echo "Failed to map port or retrieve mapped port. Check natpmpc output above." | tee -a "$LOGFILE"
        echo "" >> "$LOGFILE"
    else
        echo "VPN port mapped successfully: $MAPPED_PORT to $LISTENING_PORT" | tee -a "$LOGFILE"
        echo "" >> "$LOGFILE"
    fi

    sleep "$INTERVAL"
done

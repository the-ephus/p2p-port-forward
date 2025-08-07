# p2p-port-forward
A lightweight shell script for unRAID that enables automatic NAT-PMP port forwarding in a Docker container running a torrent client (like qBittorrent) through a VPN connection — using unRAID's built-in WireGuard support.

Tested with ProtonVPN and `linuxserver/qbittorrent`. No Gluetun or custom VPN Docker containers required.

---

## Features

- Automatically maps rotating VPN P2P ports to your torrent client's listening port
- Uses NAT-PMP (with `natpmpc`) to request forwarded ports from your VPN provider
- Installs `libnatpmp` inside your container if missing
- Minimal configuration required

---

## Requirements

- **ProtonVPN - paid plan** (or another VPN with NAT-PMP and dynamic port support)
- **Torrent Docker container** (e.g. `linuxserver/qbittorrent`)
- **User Scripts plugin** in unRAID
- unRAID 6.12+ (for built-in WireGuard support)

---

## Setup Instructions

### Step 1 – Get Your WireGuard Config from ProtonVPN

1. Log into your ProtonVPN account online.
2. Go to **Downloads** > **WireGuard Config**.
3. Choose a **P2P-enabled server**.
4. Enable **NAT-PMP** before downloading.
5. Save the `.conf` file.

### Step 2 – Import WireGuard into unRAID

1. Go to **Settings > VPN Manager** in unRAID.
2. Click **Import Tunnel** and upload your `.conf`.
3. In **Advanced View**, fix the **Peer Name** (remove any `#`).
4. Note the **Local tunnel network pool** (e.g. `10.2.0.0`) — copy this down, and we'll change the last digit to `.1` (e.g. `10.2.0.1`) for use in the script.
5. Apply and **enable** the tunnel.

### Step 3 – Attach Torrent Container to VPN Tunnel

1. Go to **Docker > Edit** your torrent container.
2. Set **Network Type** to `Custom: wg0` (or whatever your tunnel is named).
3. In the qBittorrent webUI, go to **Settings > Connection**:
    - Disable: “Use UPnP / NAT-PMP”
    - Set port to `6881` (default, but configurable)

### Step 4 – Add the Script

1. Install the **User Scripts** plugin from the unRAID Community Applications page (if not already installed).
2. Go to **Plugins > User Scripts**.
3. Add a new script (e.g., `vpn_torrent_forwarding`).
4. Paste in the contents of **p2p-port-forward-script.sh**
5. Modify these variables at the top of the script to match your setup:

   ```bash
   CONTAINER="qbittorrent"
   LISTENING_PORT="6881"
   WGTUNNEL="10.2.0.1"
   LOGFILE="/var/log/natpmp_forward.log"
   LOG_RETENTION_DAY=3
   INTERVAL=45
6. Save and set the script to run At Startup of Array.
7. Reboot your array or run the script manually to test.

### Verifying that it's working

1. Check the live output in your terminal:
   
    ```tail -f /var/log/natpmp_forward.log

2. You should see a confirmation message, for example:
   
    ```VPN port mapped successfully: 54321 to 6881

3. Within 5 minutes, your torrent client should acknowledged a fully connected client.  For example, qBittorrent will show an orange flame at the bottom for a firewalled connection. This should change to a green globe after the script runs successfully and the client updates.

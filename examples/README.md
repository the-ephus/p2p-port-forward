# Example Configuration Files

This directory contains example configurations for different scenarios.

## Basic qBittorrent Setup (examples/basic-qbittorrent.env)

Standard configuration for qBittorrent container with ProtonVPN.

## Transmission Setup (examples/transmission.env)

Configuration for Transmission container users.

## High-Traffic Setup (examples/high-traffic.env)

Optimized settings for high-traffic scenarios with longer intervals.

## Debugging Setup (examples/debug.env)

Configuration with more frequent updates for troubleshooting.

## Usage

1. Copy an example file that matches your setup
2. Customize the values for your environment
3. Source the file before running the script:
   ```bash
   source examples/basic-qbittorrent.env
   ./p2p-port-forward-script.sh
   ```

Or export the variables manually in your User Scripts configuration.
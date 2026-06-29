#!/bin/bash
# HiveOS stop script for CSD Pool Miner v0.2.0-optimized

echo "Stopping CSD Pool Miner..."

# Kill all miner processes
pkill -TERM -f "csd-gpu-miner" 2>/dev/null

# Kill tail -f log follower
pkill -f "tail -f /var/log/miner/csd-pool-miner" 2>/dev/null

# Wait up to 5 seconds for graceful shutdown
for i in $(seq 1 5); do
    if ! pgrep -f "csd-gpu-miner" > /dev/null 2>&1; then
        echo "CSD Pool Miner stopped gracefully"
        exit 0
    fi
    sleep 1
done

# Force kill
pkill -9 -f "csd-gpu-miner" 2>/dev/null
pkill -9 -f "tail -f /var/log/miner/csd-pool-miner" 2>/dev/null
echo "CSD Pool Miner force-killed"

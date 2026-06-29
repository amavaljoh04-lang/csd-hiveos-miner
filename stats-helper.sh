#!/bin/bash
# Helper script for stats collection (called by h-stats.sh if needed)
# Separate process to avoid issues with HiveOS sourcing

GPU_COUNT=${1:-1}
MINER_BIN=${2:-./csd-pool-miner-linux-nvidia}

for ((i=0; i<GPU_COUNT; i++)); do
    port=$((4000 + i))
    curl -s --connect-timeout 2 --max-time 3 "http://127.0.0.1:$port/stats" 2>/dev/null
    echo ""
done

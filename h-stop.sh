#!/bin/bash
# CSD Pool Miner — HiveOS Stop Script
cd "$(dirname "$0")"
source h-config.sh

pkill -f "$MINER_BIN" 2>/dev/null
sleep 1
# Force kill if still running
pkill -9 -f "$MINER_BIN" 2>/dev/null
# Kill any tail processes from h-run.sh
pkill -f "tail -f /dev/null" 2>/dev/null

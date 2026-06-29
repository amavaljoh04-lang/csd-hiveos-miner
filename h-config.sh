#!/bin/bash
# CSD Pool Miner — HiveOS Configuration
# This file is sourced by h-run.sh and h-stats.sh

MINER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINER_BIN="$MINER_DIR/csd-pool-miner-linux-nvidia"
MINER_LOG_DIR="/var/log/miner/csd-pool-miner"
MINER_VER="0.2.0-optimized"

# Read wallet from HiveOS config
[[ -f /hive/miners/custom/csd-pool-miner/wallet.conf ]] && source /hive/miners/custom/csd-pool-miner/wallet.conf

# Fallback: try CUSTOM_TEMPLATE from flight sheet
if [[ -z "$CUSTOM_WALLET" ]]; then
    [[ -e /hive-config/rig.conf ]] && source /hive-config/rig.conf
    CUSTOM_WALLET="$CUSTOM_TEMPLATE"
fi

# Extra args from flight sheet (e.g. --power-limit 220 --temp-limit 80)
EXTRA_ARGS=""
[[ -n "$CUSTOM_USER_CONFIG" ]] && EXTRA_ARGS="$CUSTOM_USER_CONFIG"

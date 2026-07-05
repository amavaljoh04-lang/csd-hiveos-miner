#!/usr/bin/env bash

# HiveOS run script for WarpMiner (FusionLayer / FXL)

cd /hive/miners/custom/warpminer

# Source config
[[ -f pool.cfg ]] && source pool.cfg

# Set NVIDIA OpenCL max alloc (critical for CMP 90HX and other large VRAM cards)
export GPU_MAX_ALLOC_PERCENT=95
export GPU_SINGLE_ALLOC_PERCENT=95
export CL_CONFIG_NVIDIA_MAX_ALLOC_PERCENT=95

# Remove AMD ICD files that cause SIGSEGV on NVIDIA-only rigs
if [[ ! -f /proc/driver/nvidia/version ]] || true; then
    for f in /etc/OpenCL/vendors/amdocl*.icd; do
        [[ -f "$f" ]] && mv "$f" "$f.disabled" 2>/dev/null
    done
fi

# Build command line
MINER_ARGS="-pool ${POOL_URL:-wss://eu.coin-miners.info:8443}"
MINER_ARGS="$MINER_ARGS -user ${POOL_USER:-default}"
MINER_ARGS="$MINER_ARGS -pass ${POOL_PASS:-x}"

# Parse extra config args (intensity, devices, etc.)
[[ -n "$CUSTOM_USER_CONFIG" ]] && MINER_ARGS="$MINER_ARGS $CUSTOM_USER_CONFIG"

# Create log directory if missing
mkdir -p /var/log/miner/warpminer

# Launch miner
./warpminer $MINER_ARGS 2>&1 | tee /var/log/miner/warpminer/warpminer.log

#!/bin/bash
# HiveOS run script for CSD Pool Miner v0.2.0-optimized
# Launches one miner instance per GPU (auto-detects GPU count)

MINER_DIR=/hive/miners/custom/csd-pool-miner-v0.2.0-optimized
. $MINER_DIR/h-manifest.conf
[[ -e /hive-config/wallet.conf ]] && . /hive-config/wallet.conf

MINER_BIN="$MINER_DIR/csd-gpu-miner"

# Create log directory
mkdir -p /var/log/miner/csd-pool-miner 2>/dev/null

# Wallet address from flight sheet
WALLET_ADDR="$CUSTOM_TEMPLATE"
[[ -z "$WALLET_ADDR" ]] && echo "ERROR: No wallet address set in flight sheet" && exit 1

# Parse extra config from flight sheet
EXTRA_ARGS=""
[[ ! -z "$CUSTOM_USER_CONFIG" ]] && EXTRA_ARGS="$CUSTOM_USER_CONFIG"

# Detect GPU count
GPU_COUNT=$(nvidia-smi -L 2>/dev/null | wc -l)
[[ $GPU_COUNT -eq 0 ]] && echo "ERROR: No NVIDIA GPUs found" && exit 1

echo "========================================"
echo " CSD Pool Miner v${MINER_VER} - HiveOS"
echo " Backend: cuda"
echo " GPUs detected: ${GPU_COUNT}"
echo " Wallet: ${WALLET_ADDR}"
echo " Extra args: ${EXTRA_ARGS}"
echo "========================================"

# Launch one instance per GPU
for ((i=0; i<GPU_COUNT; i++)); do
    STATS_PORT=$((4000 + i))
    echo "[GPU $i] Launching (stats: http://127.0.0.1:${STATS_PORT}/1/summary)"
    $MINER_BIN \
        --address "$WALLET_ADDR" \
        --backend cuda \
        --device $i \
        --cpu-threads 0 \
        --stats-port $STATS_PORT \
        --auto-tune \
        $EXTRA_ARGS \
        >> /var/log/miner/csd-pool-miner/csd-pool-miner_gpu${i}.log 2>&1 &
    sleep 2
done

echo "[OK] All $GPU_COUNT GPU miners launched"

# Stay in foreground — follow GPU 0 log so HiveOS sees us as running
exec tail -f /var/log/miner/csd-pool-miner/csd-pool-miner_gpu0.log

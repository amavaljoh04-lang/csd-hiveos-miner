#!/bin/bash
# CSD Pool Miner — HiveOS Run Script
# Detects all NVIDIA GPUs and launches one miner instance per device.
# Compatible with any NVIDIA GPU (GTX 10xx through RTX 50xx, CMP, Tesla, etc.)

cd "$(dirname "$0")"
source h-config.sh

mkdir -p "$MINER_LOG_DIR"

# Detect GPU count via nvidia-smi
GPU_COUNT=$(nvidia-smi -L 2>/dev/null | wc -l)
if [[ "$GPU_COUNT" -lt 1 ]]; then
    echo "ERROR: No NVIDIA GPUs detected" >&2
    exit 1
fi

echo "[CSD Miner v$MINER_VER] Detected $GPU_COUNT NVIDIA GPU(s)"

# Kill any existing instances
pkill -f "$MINER_BIN" 2>/dev/null
sleep 1

# Launch one instance per GPU
for ((GPU=0; GPU<GPU_COUNT; GPU++)); do
    STATS_PORT=$((4000 + GPU))
    LOG_FILE="$MINER_LOG_DIR/gpu${GPU}.log"
    
    $MINER_BIN \
        --address "$CUSTOM_WALLET" \
        --backend cuda \
        --device $GPU \
        --cpu-threads 0 \
        --auto-tune \
        --stats-port $STATS_PORT \
        $EXTRA_ARGS \
        >> "$LOG_FILE" 2>&1 &
    
    echo "[OK] GPU $GPU launched (PID=$!, stats port=$STATS_PORT)"
    sleep 2
done

echo "[OK] All $GPU_COUNT GPU miners launched"

# Stay in foreground so HiveOS sees us as running
exec tail -f /dev/null --pid=$(pgrep -f "$MINER_BIN" | head -1)

#!/usr/bin/env bash

# HiveOS stats script for WarpMiner (FusionLayer / FXL)
# Parses warpminer log output to report hashrate and GPU stats

LOG_FILE="/var/log/miner/warpminer/warpminer.log"

# Get last 100 lines of log for parsing
LOG_TAIL=$(tail -100 "$LOG_FILE" 2>/dev/null)

# Parse per-GPU hashrates from log lines like:
# "Device [1] hashRate: 0.258kH"
declare -a hs_arr
declare -a temp_arr
declare -a fan_arr

# Get GPU count from nvidia-smi
GPU_COUNT=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null | head -1)
[[ -z "$GPU_COUNT" ]] && GPU_COUNT=0

# Get temps and fans
if [[ $GPU_COUNT -gt 0 ]]; then
    while IFS=',' read -r temp fan; do
        temp_arr+=("${temp// /}")
        fan_arr+=("${fan// /}")
    done < <(nvidia-smi --query-gpu=temperature.gpu,fan.speed --format=csv,noheader,nounits 2>/dev/null)
fi

# Parse hashrates from most recent log entries
for ((i=1; i<=GPU_COUNT; i++)); do
    # Get last hashrate for this device
    hr=$(echo "$LOG_TAIL" | grep "Device \[$i\] hashRate:" | tail -1 | grep -oP '[\d.]+(?=kH)')
    if [[ -n "$hr" ]]; then
        # Convert kH to H (HiveOS expects kH/s in khs field)
        hs_arr+=("$hr")
    else
        hs_arr+=("0")
    fi
done

# Calculate total hashrate
total_khs=0
for hr in "${hs_arr[@]}"; do
    total_khs=$(echo "$total_khs + $hr" | bc -l 2>/dev/null || echo "$total_khs")
done

# Count accepted/rejected from log
ac=$(echo "$LOG_TAIL" | grep -c "Solutions accepted" 2>/dev/null || echo "0")
rj=$(echo "$LOG_TAIL" | grep -c "Solutions rejected" 2>/dev/null || echo "0")

# Build JSON arrays
hs_json=$(printf '%s\n' "${hs_arr[@]}" | jq -s '.' 2>/dev/null || echo "[]")
temp_json=$(printf '%s\n' "${temp_arr[@]}" | jq -s '.' 2>/dev/null || echo "[]")
fan_json=$(printf '%s\n' "${fan_arr[@]}" | jq -s '.' 2>/dev/null || echo "[]")

# Output stats JSON for HiveOS
cat <<EOF
{
  "hs": $hs_json,
  "hs_units": "khs",
  "temp": $temp_json,
  "fan": $fan_json,
  "uptime": $(( $(date +%s) - $(stat -c %Y "$LOG_FILE" 2>/dev/null || echo $(date +%s)) )),
  "ar": [$ac, $rj],
  "algo": "fusionhash",
  "ver": "2.1.0-unthrottled"
}
EOF

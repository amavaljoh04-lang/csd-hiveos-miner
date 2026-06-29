#!/bin/bash
# CSD Pool Miner — HiveOS Stats Script
# This file is SOURCED by HiveOS agent (not executed), so no exit/heredoc tricks.
# Must set: khs, stats_raw

cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || cd "$(dirname "$0")"
source h-config.sh 2>/dev/null

# Detect GPU count
local_gpu_count=$(nvidia-smi -L 2>/dev/null | wc -l)
[[ "$local_gpu_count" -lt 1 ]] && local_gpu_count=1

# Collect stats from each GPU's stats port
local_hs_arr=""
local_temp_arr=""
local_fan_arr=""
local_total_khs=0
local_accepted=0
local_rejected=0
local_uptime=0
local_bus_arr=""

for ((i=0; i<local_gpu_count; i++)); do
    port=$((4000 + i))
    # Get stats JSON from miner's HTTP stats endpoint
    stats_json=$(curl -s --connect-timeout 2 --max-time 3 "http://127.0.0.1:$port/stats" 2>/dev/null)
    
    if [[ -n "$stats_json" && "$stats_json" != *"error"* ]]; then
        # Parse hashrate (MH/s from miner, convert to kH/s for HiveOS)
        gpu_mhs=$(echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hashrate_mhs',0))" 2>/dev/null)
        gpu_temp=$(echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('temperature',0))" 2>/dev/null)
        gpu_fan=$(echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('fan_pct',0))" 2>/dev/null)
        gpu_accepted=$(echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('shares_accepted',0))" 2>/dev/null)
        gpu_rejected=$(echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('shares_rejected',0))" 2>/dev/null)
        gpu_uptime=$(echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uptime_secs',0))" 2>/dev/null)
        
        [[ -z "$gpu_mhs" ]] && gpu_mhs=0
        [[ -z "$gpu_temp" ]] && gpu_temp=0
        [[ -z "$gpu_fan" ]] && gpu_fan=0
        [[ -z "$gpu_accepted" ]] && gpu_accepted=0
        [[ -z "$gpu_rejected" ]] && gpu_rejected=0
        [[ -z "$gpu_uptime" ]] && gpu_uptime=0
        
        # Convert MH/s to kH/s (multiply by 1000)
        gpu_khs=$(echo "$gpu_mhs * 1000" | bc 2>/dev/null || echo "0")
        gpu_khs=${gpu_khs%.*}
    else
        # Fallback: try hiveos-stats subcommand
        hs_line=$($MINER_BIN hiveos-stats --stats-port $port 2>/dev/null | grep -o '"hashrate_mhs":[0-9.]*' | cut -d: -f2)
        gpu_khs=0
        [[ -n "$hs_line" ]] && gpu_khs=$(echo "$hs_line * 1000" | bc 2>/dev/null || echo "0") && gpu_khs=${gpu_khs%.*}
        gpu_temp=0
        gpu_fan=0
        gpu_accepted=0
        gpu_rejected=0
        gpu_uptime=0
    fi
    
    # Build arrays
    [[ -n "$local_hs_arr" ]] && local_hs_arr="$local_hs_arr, "
    local_hs_arr="${local_hs_arr}${gpu_khs}"
    
    [[ -n "$local_temp_arr" ]] && local_temp_arr="$local_temp_arr, "
    local_temp_arr="${local_temp_arr}${gpu_temp}"
    
    [[ -n "$local_fan_arr" ]] && local_fan_arr="$local_fan_arr, "
    local_fan_arr="${local_fan_arr}${gpu_fan}"
    
    local_total_khs=$((local_total_khs + gpu_khs))
    local_accepted=$((local_accepted + gpu_accepted))
    local_rejected=$((local_rejected + gpu_rejected))
    [[ "$gpu_uptime" -gt "$local_uptime" ]] && local_uptime=$gpu_uptime
    
    # Get PCI bus ID for GPU mapping
    bus_id=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader,nounits -i $i 2>/dev/null | grep -oP '\d+(?=:00\.0)')
    [[ -z "$bus_id" ]] && bus_id="0"
    [[ -n "$local_bus_arr" ]] && local_bus_arr="$local_bus_arr, "
    local_bus_arr="${local_bus_arr}\"$(printf '%02x' $((16#$bus_id)) 2>/dev/null || echo $bus_id):00.0\""
done

# Set variables that HiveOS reads
khs=$local_total_khs

stats_raw=$(cat <<STATSEOF
{
  "hs": [$local_hs_arr],
  "hs_units": "khs",
  "temp": [$local_temp_arr],
  "fan": [$local_fan_arr],
  "uptime": $local_uptime,
  "ver": "$MINER_VER",
  "algo": "sha256d",
  "ar": [$local_accepted, $local_rejected],
  "bus_numbers": [$local_bus_arr]
}
STATSEOF
)

stats=$stats_raw

#!/bin/bash
# Stats helper - called as a subprocess (not sourced)
# Returns JSON stats for HiveOS

GPU_COUNT=$(nvidia-smi -L 2>/dev/null | wc -l)
if [[ $GPU_COUNT -eq 0 ]]; then
    echo '{"hs":[],"hs_units":"khs","temp":[],"fan":[],"uptime":0,"ver":"0.2.0-optimized","algo":"sha256d","ar":[0,0]}'
    exit 0
fi

# Collect hashrates from each GPU stats port
HS_ARRAY=""
ACCEPTED=0
REJECTED=0

for ((i=0; i<GPU_COUNT; i++)); do
    PORT=$((4000 + i))
    RESP=$(curl -s --max-time 2 "http://127.0.0.1:${PORT}/1/summary" 2>/dev/null)
    if [[ ! -z "$RESP" && "$RESP" == *"hashrate"* ]]; then
        # Parse hashrate (H/s to kH/s)
        HS=$(echo "$RESP" | python3 -c "import sys,json;d=json.load(sys.stdin);hr=d.get('hashrate',{}).get('total',[0]);print(int(hr[0]/1000) if isinstance(hr,list) and len(hr)>0 else 0)" 2>/dev/null)
        A=$(echo "$RESP" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('results',{}).get('shares_good',0))" 2>/dev/null)
        R=$(echo "$RESP" | python3 -c "import sys,json;d=json.load(sys.stdin);r=d.get('results',{});print(r.get('shares_total',0)-r.get('shares_good',0))" 2>/dev/null)
    else
        HS=0; A=0; R=0
    fi
    [[ -z "$HS" ]] && HS=0
    [[ -z "$A" ]] && A=0
    [[ -z "$R" ]] && R=0
    [[ ! -z "$HS_ARRAY" ]] && HS_ARRAY="${HS_ARRAY},"
    HS_ARRAY="${HS_ARRAY}${HS}"
    ACCEPTED=$((ACCEPTED + A))
    REJECTED=$((REJECTED + R))
done

# Temps and fans
TEMP_ARRAY=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | paste -sd ',' -)
FAN_ARRAY=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null | paste -sd ',' -)

# Uptime from oldest miner process
OLDEST_PID=$(pgrep -f "csd-gpu-miner" -o 2>/dev/null)
if [[ ! -z "$OLDEST_PID" && -d "/proc/$OLDEST_PID" ]]; then
    START_TIME=$(stat -c %Y /proc/$OLDEST_PID 2>/dev/null || echo $(date +%s))
    UPTIME=$(( $(date +%s) - START_TIME ))
else
    UPTIME=0
fi

# Bus numbers for per-GPU mapping
BUS_ARRAY=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader,nounits 2>/dev/null | python3 -c "
import sys
buses = []
for line in sys.stdin:
    line = line.strip()
    # Format: 00000000:XX:00.0 - extract XX as decimal
    parts = line.split(':')
    if len(parts) >= 3:
        buses.append(str(int(parts[1], 16)))
print(','.join(buses))
" 2>/dev/null)

echo "{\"hs\":[$HS_ARRAY],\"hs_units\":\"khs\",\"temp\":[$TEMP_ARRAY],\"fan\":[$FAN_ARRAY],\"bus_numbers\":[$BUS_ARRAY],\"uptime\":$UPTIME,\"ver\":\"0.2.0-optimized\",\"algo\":\"sha256d\",\"ar\":[$ACCEPTED,$REJECTED]}"

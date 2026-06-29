#!/bin/bash
# HiveOS stats script for CSD Pool Miner v0.2.0-optimized
# NOTE: This script is SOURCED by HiveOS agent, not executed directly
# Do NOT use 'exit' - it will kill the parent process

MINER_DIR=/hive/miners/custom/csd-pool-miner-v0.2.0-optimized

[[ -f $MINER_DIR/h-manifest.conf ]] && source $MINER_DIR/h-manifest.conf

# Call the stats helper (separate process)
stats=$($MINER_DIR/stats-helper.sh 2>/dev/null)

# Parse khs from the JSON
if [[ ! -z "$stats" ]]; then
    khs=$(echo "$stats" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    hs = d.get('hs', [])
    total = sum(hs) if hs else 0
    print(total)
except:
    print(0)
" 2>/dev/null)
    [[ -z "$khs" ]] && khs=0
else
    khs=0
    stats='{"hs":[],"hs_units":"khs","temp":[],"fan":[],"uptime":0,"ver":"0.2.0-optimized","algo":"sha256d","ar":[0,0]}'
fi

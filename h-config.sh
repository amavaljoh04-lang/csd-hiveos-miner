#!/usr/bin/env bash

# HiveOS config script for WarpMiner (FusionLayer / FXL)
# Reads wallet.conf and generates pool.cfg

[[ -z $CUSTOM_TEMPLATE ]] && CUSTOM_TEMPLATE="%WAL%"
[[ -z $CUSTOM_URL ]] && CUSTOM_URL="wss://eu.coin-miners.info:8443"

POOL_URL="$CUSTOM_URL"
POOL_USER="$CUSTOM_TEMPLATE"
POOL_PASS="${CUSTOM_PASS:-x}"

# Convert stratum+tcp:// to wss:// if needed (FXL uses WebSocket)
POOL_URL="${POOL_URL/stratum+tcp:\/\//wss://}"
POOL_URL="${POOL_URL/stratum+ssl:\/\//wss://}"

# Write config file
cat > /hive/miners/custom/warpminer/pool.cfg <<EOF
POOL_URL=$POOL_URL
POOL_USER=$POOL_USER
POOL_PASS=$POOL_PASS
EOF

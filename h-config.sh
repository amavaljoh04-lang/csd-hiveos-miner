#!/bin/bash
# HiveOS config script for CSD Pool Miner v0.2.0-optimized
MINER_DIR=/hive/miners/custom/csd-pool-miner-v0.2.0-optimized
. $MINER_DIR/h-manifest.conf
[[ -e /hive-config/wallet.conf ]] && . /hive-config/wallet.conf

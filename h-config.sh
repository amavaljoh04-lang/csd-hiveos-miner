#!/bin/bash
# HiveOS config script for CSD Pool Miner
MINER_DIR=/hive/miners/custom/csd-pool-miner-v0.1.16
. $MINER_DIR/h-manifest.conf
[[ -e /hive-config/wallet.conf ]] && . /hive-config/wallet.conf

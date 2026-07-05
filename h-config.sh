#!/bin/bash
# HiveOS config script for CSD Pool Miner v0.2.0-optimized
MINER_DIR=/hive/miners/custom/csd-pool-miner
. $MINER_DIR/h-manifest.conf
[[ -e /hive-config/wallet.conf ]] && . /hive-config/wallet.conf

function miner_ver() {
    echo ""
}

function miner_config_gen() {
    return 0
}

function miner_fork() {
    echo ""
}

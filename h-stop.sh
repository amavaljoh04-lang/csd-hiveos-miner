#!/usr/bin/env bash

# HiveOS stop script for WarpMiner
pkill -f "warpminer" 2>/dev/null
sleep 1
pkill -9 -f "warpminer" 2>/dev/null

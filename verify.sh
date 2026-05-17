#!/bin/bash

# Integration Verification Script for Infinity-Cache Proxy
# Launches both Core Engine and Interception Daemon in parallel.

echo "[INIT] Compiling workspace..."
cargo build

# Function to cleanup background processes on exit
cleanup() {
    echo "[INIT] Shutting down..."
    kill $(jobs -p)
    exit
}
trap cleanup EXIT

echo "[INIT] Starting Core Engine..."
cargo run -p infinity_cache_core &
CORE_PID=$!

# Wait for core to initialize and bind socket
sleep 3

echo "[INIT] Starting Interception Daemon..."
cargo run -p infinity_cache_daemon &
DAEMON_PID=$!

sleep 2

echo "[TEST] Simulating a high-write event in 'scratch_disk'..."
echo "Simulated build artifact" > scratch_disk/build.log
echo "Simulated cargo target data" >> scratch_disk/build.log

sleep 5

echo "[TEST] Verification complete. Check logs above for CORE/DAEMON trace."
echo "[TEST] Press Ctrl+C to stop the software twin."

wait

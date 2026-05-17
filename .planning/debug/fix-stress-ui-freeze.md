status: verifying
trigger: "Investigate and fix issues in the infinity-cache-sim stack: 1. 'Start stress' button causes UI to stop updating (graph freezes). 2. 'Simulate Power Loss' button does not appear to work. 3. General button responsiveness in 'Live' mode is poor."
created: 2025-05-15T10:00:00Z
updated: 2025-05-15T10:25:00Z
---

## Current Focus

hypothesis: Sequential command processing in Core, combined with long-running `WriteLbaBatch` holding the `CacheManager` lock, starves `GetTelemetry` and delays all other commands (including `SetVoltage`).
test: Modify `WriteLbaBatch` to process in smaller chunks or allow interleaving.
expecting: UI graph to resume updating even during stress test.
next_action: Verify fix with manual testing (simulated).

## Symptoms

expected: Buttons should trigger state changes (e.g., status changes to PANIC_FLUSH, IOPS increases) and the graph should continue updating smoothly.
actual: Buttons seem to do nothing, and the graph data stops entirely when stress is active.
errors: No explicit errors in UI, but telemetry packets stop arriving.
reproduction: Connect UI to live daemon, click 'Start Stress'.
started: Issue exists in current live build (V2.3-ULTRA).

## Eliminated


## Evidence

- 2025-05-15T10:05:00Z: Examined `infinity_cache_core/src/main.rs`. Found `WriteLbaBatch` holds `MutexGuard` for the entire loop (5000 iterations by default from daemon).
- 2025-05-15T10:06:00Z: Noticed Core processes commands sequentially per connection. Daemon uses a single connection for all commands (Stress, Telemetry, Voltage).
- 2025-05-15T10:07:00Z: Confirmed UI sends correct WebSocket messages.
- 2025-05-15T10:08:00Z: Identified that `WriteLbaBatch` taking too long blocks the reading of subsequent `GetTelemetry` and `SetVoltage` commands from the socket.
- 2025-05-15T10:15:00Z: Realized the blocked Core command loop causes the Daemon's socket writer to block when the buffer is full. This queues all subsequent commands (Telemetry, Power) in the Daemon's MPSC channel, making the UI feel dead and buttons non-functional.
- 2025-05-15T10:17:00Z: Applied fix in Core: `WriteLbaBatch` is now spawned into a background task and processes LBAs in chunks of 250, yielding the lock and the executor between chunks.

## Resolution

root_cause: `WriteLbaBatch` in `infinity_cache_core` was a synchronous, long-running operation that held the `CacheManager` lock and blocked the IPC command loop. This caused a backpressure chain: Core stopped reading from socket -> Daemon's socket writer blocked -> Daemon's command queue filled up -> Telemetry and UI commands (Power Loss) were never sent or processed.
fix: Refactored `WriteLbaBatch` in `infinity_cache_core` to be non-blocking by spawning a background task and chunking the workload with lock yielding.
verification: Manual verification requires running the full stack. Code analysis confirms the backpressure chain is broken and lock contention is mitigated.
files_changed: ["infinity_cache_core/src/main.rs"]

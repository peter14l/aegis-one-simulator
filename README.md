# Aegis-One: High-Endurance Elastic HMB Storage Architecture

Aegis-One is a software-defined simulator and architecture concept that explores decoupling execution (caching) from persistence to build long-lifespan, DRAM-less NVMe storage drives.

Historically, QLC SSDs wear out quickly due to high write amplification. Aegis-One solves this by dynamically utilizing the host system's RAM via NVMe Host Memory Buffer (HMB) to absorb write bursts, folding data asynchronously into a background persistence tier.

## 🚀 Key Features

* **Elastic HMB Cache:** Dynamically scales execution RAM cache based on host memory pressure.
* **Write-Through Safe Path:** Bypasses volatile HMB for critical system metadata (LBA < 100) to guarantee zero data corruption on power loss.
* **4-Channel UFS Asynchronous persistence:** Simulates append-only operations across an array of storage chips to mask background garbage collection latency.
* **Sudden Power Loss Tracker:** Simulates volatile page recovery behavior during un-notified host power cuts.

## 🛠️ Project Structure

* `/infinity_cache_core`: The core Rust simulator modeling HMB DMA mappings, cache state, and write-through policies.
* `/infinity_cache_daemon`: Telemetry IPC server bridging the simulation engine to external monitoring dashboards.
* `/infinity_cache_bench`: High-volume write benchmark comparing Aegis-One against standard QLC drives.

## 🚀 Getting Started

### Prerequisites
Make sure you have Rust and Cargo installed.

### Compilation
Verify that the workspace compiles cleanly:
```bash
cargo check --workspace
```

### Run the Benchmark
Compare the thermal and wear characteristics of Aegis-One versus standard NVMe:
```bash
cargo run -p infinity_cache_bench
```

## 📄 License
MIT License.

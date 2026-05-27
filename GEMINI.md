# Project Aegis-One: Architecture & Context Guide

## 1. Project Vision
**Aegis-One (The Ultra-Endurance Burst Drive)** is an innovative storage architecture designed to replace traditional wear-prone QLC NVMe SSDs. It targets developers, AI researchers, and video editors by mitigating heavy write amplification through intelligent caching and commodity flash components, drastically reducing total cost of ownership (TCO) and e-waste.

## 2. The Architectural Evolution
This project went through a rigorous "deep-tech teardown" that forced a pivot from a fragile prototype to a commercially viable enterprise-grade design.

### Phase 1: The "Hackathon" Concept (Abandoned)
*   **Design:** 32GB LPDDR5 + 8x eMMC 5.1 (RAID-0) + 50-second Supercapacitors + OS Symlink Daemon.
*   **Fatal Flaws:** Supercapacitors degrade at M.2 temperatures; eMMC RAID-0 introduces massive garbage collection stutter; a 50s power-loss flush is mathematically and physically unreliable; OS symlink daemons break critical filesystem tools (Git, AV, VSS).

### Phase 2: The "Physics-Restricted" Pivot (Transitional)
*   **Design:** 8GB LPDDR5 + UFS 4.0 Asynchronous Array + Raw SLC Emergency Log + Tantalum Capacitors.
*   **Fatal Flaws:** While physically sound, shrinking the cache to 8GB lost the "infinite endurance / infinite capacity" marketing magic, limiting its utility for massive workstation workloads.

### Phase 3: The "Elastic HMB" Architecture (Current & Final)
We broke the "Hardware Isolation" constraint to solve the physics/capacity paradox.
*   **Form Factor:** Standard M.2 2280 NVMe (Ultra-slim < 2.25mm Z-height).
*   **Execution Tier (Cache):** **NVMe HMB (Host Memory Buffer) / CXL.mem.** The drive has NO massive onboard DRAM. It dynamically borrows RAM from the host laptop/PC.
    *   *Dynamic Allocation:* Scales from borrowing 512MB on an 8GB laptop to 16GB+ on a 64GB workstation. Gives memory back to the OS instantly under memory pressure.
*   **Persistence Tier:** **UFS 4.0 Asynchronous Array**. High bandwidth, low pin count, natively fast.
*   **Fallback Tier:** **Pseudo-SLC Mode** on the UFS chips. When the dynamic HMB cache fills during a massive burst, writes cascade into the fast, high-endurance SLC partition before folding into TLC/QLC.
*   **Power-Loss Protection:** Relies on the host system's power (laptop battery/UPS) to safely flush the HMB to the drive during ACPI Critical Battery / S3/S4 sleep states. No massive onboard supercapacitors required.
*   **BOM Advantage:** Drastically cheaper to manufacture (No LPDDR5 chips, no supercaps, simpler PCB routing).

## 3. Engineering Directives for the AI Assistant
When assisting with this codebase, adhere to the following rules:
1.  **HMB-First Thinking:** The Rust firmware simulator and Verilog must model a storage controller interacting with *host memory* via PCIe DMA, not local physical DRAM.
2.  **Dynamic Scaling:** Benchmarks and tests should evaluate how the system handles cache exhaustion and dynamic resizing based on simulated host memory pressure.
3.  **No OS-Level Hacks:** Do not suggest user-space daemons for file manipulation. The drive presents as a standard NVMe block device. All "magic" happens in the controller firmware / HMB allocation.
4.  **Hostile Environment Mindset:** Always consider unexpected power loss, PCIe resets, OS crashes, and thermal throttling in your code and simulations.

## 4. Current Codebase State
*   `INFINITY_DRIVE_TOTAL_REPLACEMENT_PRD.md` & `infinity-cache-proxy-prd.md`: Updated to reflect the earlier hardware pivot, but **need to be updated to reflect the final "Elastic HMB" pivot**.
*   `infinity_cache_core/`: Rust FTL simulator. Currently hardcoded for 8GB local RAM limits. **Needs refactoring to simulate Dynamic HMB.**
*   `infinity_cache_daemon/`: Gutted of symlink logic. Acts as a telemetry relay.
*   `*.v` (Verilog): Currently models local LPDDR5 and SLC. **Needs to be adjusted for PCIe HMB DMA logic.**

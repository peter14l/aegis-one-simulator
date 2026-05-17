# Product Requirements Document
## Project Infinity-Cache Proxy (Modular Edition)
### Revision 1.0 — Engineering & Investor Grade

**Classification:** Confidential — Pre-Series A
**Authors:** Principal Deep-Tech PM / Hardware Systems Architecture Team
**Date:** 2026-05

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technical Hardware Architecture & Split-Board Specifications](#2-technical-hardware-architecture--split-board-specifications)
3. [Functional Specifications & State Machine](#3-functional-specifications--state-machine)
4. [Firmware & Smart Caching Software Stack](#4-firmware--smart-caching-software-stack)
5. [Commercialization, Unit Economics & Life Cycles](#5-commercialization-unit-economics--life-cycles)
6. [Key Risks & Mitigations](#6-key-risks--mitigations)
7. [Appendices](#7-appendices)

---

## 1. Executive Summary

### 1.1 Problem Statement

The 2026 NAND flash market is experiencing a structural supply crisis driven by two compounding forces:

**Supply Compression — AI Datacenter Absorption:** Hyperscalers (AWS, Google, Microsoft Azure, and their GPU-cluster tenants) have consumed the overwhelming majority of 3D NAND wafer-out capacity from Samsung, SK Hynix, and Micron, prioritizing high-density QLC enterprise drives for training checkpoint storage. Consumer-facing SSD supply chains are consequently starved, driving retail NVMe SSD prices upward and diminishing quality tiers as manufacturers substitute premium TLC cells with cost-reduced QLC to preserve margin.

**Demand-Side Degradation — Write Amplification Under Power Users:** QLC NAND carries a rated endurance of approximately 100–150 Program/Erase (P/E) cycles per cell, translating to 0.1–0.3 Drive Writes Per Day (DWPD) on a typical 2TB consumer drive. For the target professional workload class — code compilation pipelines (`npm build`, `cargo build`, `cmake`), video editing scratch disks (DaVinci Resolve, Premiere Pro, CapCut), and containerized development environments — real-world write amplification factors of 3–8× routinely reduce effective NAND lifespan to 12–18 months under sustained professional use. This represents de facto planned obsolescence at a $120–$200 price point, with no economically viable recourse for the end user short of drive replacement.

**Market Gap:** No current commercially available storage product addresses the intersection of (a) consumer M.2 NVMe form-factor compatibility, (b) true infinite write endurance at the primary storage layer, (c) sub-$60 total acquisition cost, and (d) a monetizable software ecosystem. Enterprise-class Optane/3D XPoint technology addressed (a) and (b) but was discontinued by Intel in 2022 and never achieved consumer pricing. Battery-backed DRAM RAID devices (NVDIMM-P) address (b) at enterprise scale but have no M.2 equivalent.

### 1.2 Solution Overview

**Project Infinity-Cache Proxy** is a modular M.2 2280 NVMe storage proxy architecture engineered on a **split-board commercial design** that isolates hardware lifecycle characteristics into two distinct, independently replaceable assemblies:

| Assembly | Lifecycle Class | Core BOM Driver | User Behavior |
|---|---|---|---|
| **Base Carrier Board** | Permanent (5–10 year) | FPGA/ASIC + Supercapacitors | One-time purchase |
| **Memory Cartridge** | Consumable (density-upgrade driven) | LPDDR4 + eMMC | Upgrade as data demands grow |

The LPDDR4 volatile write buffer on the cartridge provides **effectively unlimited write endurance** at the primary storage tier — DRAM P/E cycles are measured in the quadrillions. The eMMC persistence vault provides non-volatile data safety during power events. Neither component ages via write stress in any economically relevant sense within a 5-year product horizon.

Revenue is generated through the **Razor-and-Blade cartridge model** and a **SaaS daemon subscription** that intelligently extends the proxy's value surface into the host OS software layer, creating durable lock-in without compromising the open-source hardware positioning.

### 1.3 Strategic Differentiation

| Dimension | QLC Consumer NVMe | Enterprise Optane | Infinity-Cache Proxy |
|---|---|---|---|
| Write Endurance | 0.1–0.3 DWPD | ~60 DWPD | Effectively ∞ (DRAM-bound) |
| M.2 2280 Compatible | ✅ | ❌ (U.2/E1.S) | ✅ |
| Consumer Price Target | $100–$200 | $800–$4,000+ | $39–$55 base + $12–$15 cartridge |
| Upgrade Path | Drive replacement | None (EOL) | Cartridge density upgrade |
| Software Ecosystem | None | None | Daemon + SaaS tier |
| Open Source Hardware | ❌ | ❌ | ✅ (KiCad + HDL) |

---

## 2. Technical Hardware Architecture & Split-Board Specifications

### 2.1 Form Factor & Mechanical Envelope

The device presents as a standard **M.2 2280** module (22 mm × 80 mm) to the host system. All M.2 sockets use the **M-key** edge connector (75-pin, PCIe × 4 + USB 2.0 signal set). The split-board architecture is invisible to the host — the PCIe bus enumerates a single NVMe device as if interacting with a monolithic drive.

**Mechanical Stack:**

```
Host M.2 Socket (M-key, M.2 spec compliant)
        │
        ▼
┌──────────────────────────────────┐
│        BASE CARRIER BOARD        │  PCB thickness: 0.8 mm
│  (22 mm × 80 mm × ~3.5 mm tall) │  Component height budget: ~2.7 mm
│                                  │
│  [Mezzanine Socket — top face]   │  ← Board-to-board connector, center-aligned
└──────────────────────────────────┘
        │ (Mezzanine Interface)
        ▼
┌──────────────────────────────────┐
│      MEMORY CARTRIDGE PCB        │  PCB thickness: 0.6 mm
│   (20 mm × 60 mm × ~2.0 mm tall)│  Smaller footprint, top-loaded
└──────────────────────────────────┘

Total assembled height: ~6.5 mm
M.2 spec max component height (single-sided): 1.5 mm (2280-S1)
M.2 spec max component height (double-sided): 1.5 mm per side (2280-D1)
```

> **Critical Mechanical Constraint:** Standard M.2 2280 height budgets (per PCI-SIG M.2 specification, Rev 1.0) are 1.5 mm single-sided. The assembled proxy stack at ~6.5 mm **exceeds** this limit. This is architecturally acceptable under two deployment modes:
>
> 1. **Desktop/Tower PCIe Adapter Mode:** The device mounts in an M.2-to-PCIe x4 slot adapter card, providing unrestricted vertical clearance. This is the primary target deployment for the V1.0 product.
> 2. **Custom OEM Riser/Bracket Mode:** OEM laptop/embedded partners integrate a custom M.2 riser socket with a 7 mm height clearance. This is a V2.0 commercial avenue.

### 2.2 Mezzanine Connector Specification

The inter-board mechanical and electrical interconnect is the most critical reliability element of the architecture. The design uses a **Board-to-Board (B2B) Mezzanine Connector** stack, sourced from established connector families (e.g., Hirose DF40 Series, Molex Milli-Grid, or Samtec BSH/BSS Series) to ensure supply chain availability and proven reliability data.

**Connector Requirements:**

| Parameter | Specification | Justification |
|---|---|---|
| Pitch | 0.4 mm or 0.5 mm | Space budget within 22 mm PCB width |
| Pin Count | 80–100 pins | Signal + power + ground density |
| Mated height | 1.0 mm or 1.5 mm | Total stack height constraint |
| Current rating per pin | ≥ 0.5 A | LPDDR4 VDD burst current demands |
| Mating cycles | ≥ 30 cycles rated | Cartridge upgrade lifecycle |
| Operating temp | -40°C to +85°C | Matches LPDDR4 and eMMC specs |
| Vibration (IEC 60068-2-6) | 10–500 Hz, 5G | Desktop/workstation shock profile |

**Signal Routing Across Mezzanine:**

| Signal Group | Pin Allocation | Notes |
|---|---|---|
| LPDDR4 Data Bus (DQ[63:0]) | 64 pins | Full 64-bit width, length-matched |
| LPDDR4 Command/Address | 12 pins | CA[9:0], CKE, CS |
| LPDDR4 Clock (differential) | 4 pins | CK_t/CK_c × 2 |
| eMMC Data (DAT[7:0]) | 8 pins | eMMC 5.1, HS400 mode |
| eMMC Command/Clock | 2 pins | CMD, CLK |
| Power Rails (VDD1.1, VDD1.8) | 8 pins | 4 per rail for current derating |
| Ground | 16 pins | Distributed ground return |
| Cartridge ID / EEPROM | 2 pins | I²C for cartridge metadata |
| Reserved / GPIO | 4 pins | Future expansion |

### 2.3 Base Carrier Board — Component Architecture

The base carrier board is the permanent, non-consumable investment. Its bill of materials is optimized for longevity and electrical robustness, not density.

#### 2.3.1 PCIe/NVMe Bridge: FPGA or Custom ASIC

**Role:** Translate PCIe Gen 3.0/4.0 × 4 (host-side) to the proprietary mezzanine memory bus (device-side), implementing the NVMe command set in firmware.

**FPGA Prototyping Phase (V0.1 — V0.9):**

- Target device: **Lattice ECP5-25F** (25K LUTs, available in CABGA256, PCIe Gen 2 × 4 hard IP, low power, open-source toolchain via Yosys/nextpnr)
- PCIe IP: Lattice PCIe hard IP block instantiated from the ECP5 reference design
- NVMe command processing: Implemented in synthesizable Rust (using `rust-hdl` or hand-crafted RTL) targeting the FPGA fabric
- LPDDR4 PHY: Soft LPDDR4 controller implemented in fabric; this is the primary FPGA resource consumer (~15K LUT estimate) and the main technical risk item requiring dedicated PHY bring-up effort

**ASIC Path (V1.0 — Production):**

- Engage a fabless ASIC design house (e.g., targeting TSMC 22nm ULP node) for a custom NVMe-to-LPDDR4 bridge ASIC
- Expected die area: ~4 mm² at 22nm for NVMe Gen 4 × 4 + dual-channel LPDDR4-4266 + power management integration
- NRE cost estimate: $800K–$1.5M at 22nm MPW (Multi-Project Wafer) shuttle; $3–5M for dedicated tape-out at volume
- ASIC unit cost at 50K volume: ~$6–8 per device

#### 2.3.2 Power Delivery, Supercapacitor Array & PMIC

**Role:** Provide reliable, conditioned power to all components and store sufficient energy to complete a full LPDDR4-to-eMMC emergency flush on unplanned power loss.

**Supercapacitor Array:**

The energy required for an emergency DMA flush is calculated as follows:

```
Flush workload:
  LPDDR4 capacity:          32 GB (target cartridge)
  eMMC HS400 throughput:    ~300 MB/s sustained write
  Flush duration (worst):   32,000 MB / 300 MB/s ≈ 107 seconds

  Note: In practice, only the "dirty" (unsynced) portion of LPDDR4 needs 
  flushing. Under a typical write workload, dirty data is bounded by the 
  OS's writeback window (default: 5 seconds × write bandwidth). At 3 GB/s 
  sequential write, maximum dirty window = ~15 GB. Realistic flush 
  duration: 15,000 MB / 300 MB/s = 50 seconds.

Power consumption during flush:
  LPDDR4 (active read):     ~1.5 W (32 GB LPDDR4 array, active read mode)
  eMMC (active write):      ~0.8 W
  FPGA/ASIC (DMA engine):   ~0.5 W
  PMIC + misc:              ~0.2 W
  Total:                    ~3.0 W

Energy required (50s flush at 3W):
  E = P × t = 3.0 W × 50 s = 150 J

Supercapacitor sizing (E = ½CV²):
  Target V_initial = 3.3 V (M.2 supply), V_cutoff = 1.8 V (minimum for 
  LPDDR4 retention read)
  C = 2E / (V_i² - V_c²) = 2 × 150 / (3.3² - 1.8²) = 300 / (10.89 - 3.24)
  C = 300 / 7.65 ≈ 39.2 F

  Recommended: 2× 22F supercapacitors in parallel = 44F total (10% margin)
  Target device: Vishay/Nichicon low-profile EDLC, 3.3V rated, 
                 ≤ 2.5 mm height, ≤ 10 mm diameter
```

**PMIC (Power Management IC):**

- Input voltage monitoring: Continuous ADC sampling of V_cc3.3 at 10 kHz; interrupt triggered at V_in < 2.9 V (150 mV headroom above M.2 3.3V minimum)
- Power rail sequencing on startup: Supercap pre-charge → LPDDR4 VDD1.1 → LPDDR4 VDD1.8 → eMMC VCC → FPGA core → PCIe assertion
- Hot-swap isolation: Integrated load switch (e.g., TI TPS22929 or similar) electrically isolates the M.2 PCIe bus from host within < 5 µs of power-loss interrupt
- Recommended PMIC: TI TPS65988 family or custom gate-drive solution around a discrete MOSFETs + comparator; final selection pending thermal analysis

### 2.4 Memory Cartridge — Component Architecture

The cartridge is the **consumable upgrade unit**. It must be manufacturable at sub-$15 BOM cost, physically compact, and electrically robust across the mezzanine interface.

#### 2.4.1 Primary Write Cache: LPDDR4 Module

**Role:** Serve as the primary, infinite-endurance storage layer for the proxy. All host write I/O is absorbed here first.

| Parameter | V1.0 Cartridge | V2.0 Cartridge |
|---|---|---|
| Capacity | 16 GB | 32 GB |
| Speed | LPDDR4-3200 | LPDDR4X-4266 |
| Bus width | 64-bit (single channel) | 128-bit (dual channel) |
| Sequential write BW | ~25 GB/s (DRAM-native) | ~50 GB/s |
| Endurance | > 10^15 write cycles | > 10^15 write cycles |
| Package | FBGA-200 or PoP | FBGA-200 dual-die stack |
| Retention (no power) | ~64 ms (DRAM refresh) | ~64 ms (DRAM refresh) |
| BOM cost estimate | ~$8–10 at volume | ~$14–16 at volume |

> **Retention Architecture Note:** LPDDR4 is volatile. Data in the write buffer that has not been committed to the eMMC vault will be lost if power is removed and the supercapacitor emergency flush is not triggered. The firmware implements a **continuous background writeback** scheme (see Section 3) to minimize the volatile dirty window, ensuring ≤ 5 seconds of write data is at risk under normal operating conditions.

#### 2.4.2 Persistence Vault: eMMC Storage

**Role:** Receive persistent snapshots of LPDDR4 structural mapping during graceful shutdown and emergency power-loss flush. Acts as the non-volatile ground truth for data recovery.

| Parameter | Specification |
|---|---|
| Capacity | 32 GB (V1.0), 64 GB (V2.0) |
| Interface | eMMC 5.1, HS400 (200 MB/s) |
| Endurance | ~3,000 P/E cycles (MLC-class eMMC) |
| DWPD at 32 GB | 0.4 DWPD (well within eMMC limits given flush-only write pattern) |
| Package | BGA-153, 11.5 × 13 mm |
| BOM cost | ~$2–3 at volume |
| Recommended vendors | Micron MTFC32GAPALBH, Kingston eMMC, Western Digital iNAND 7250A |

**eMMC Endurance Justification:** The eMMC receives writes only during (a) graceful shutdown sync events (≤ 32 GB per event) and (b) emergency flush events. Under normal professional use, a machine may be shut down ~2× per day. Daily write volume to eMMC = 2 × dirty_window ≤ 2 × 15 GB = 30 GB/day. At 3,000 P/E cycles on 32 GB eMMC → total endurance = 3,000 × 32 GB = 96 TB written. At 30 GB/day → lifespan = 96 TB / 30 GB/day ≈ 8.7 years. The eMMC outlives the product generation.

#### 2.4.3 Cartridge Metadata EEPROM

A small (4 Kbit) I²C EEPROM (e.g., Microchip 24AA04) on the cartridge stores:

- Cartridge serial number and manufacturing date
- Installed LPDDR4 capacity and speed grade
- eMMC capacity and firmware version
- Flush event log (last 16 entries with timestamp + dirty-data size)
- Remaining eMMC endurance estimate (updated on each flush)

This metadata is read by the base board PMIC on cartridge insertion and surfaced to the host daemon software via a vendor-specific NVMe log page.

---

## 3. Functional Specifications & State Machine

### 3.1 System State Diagram

```
                        ┌─────────────────┐
                        │   POWER_OFF /   │
                        │   CARTRIDGE_OUT │
                        └────────┬────────┘
                                 │ Power applied + cartridge detected
                                 ▼
                        ┌─────────────────┐
                        │   INIT_SEQUENCE │
                        │  (POST / BIST)  │
                        └────────┬────────┘
                                 │ eMMC vault loaded → LPDDR4 hydrated
                                 ▼
                    ┌────────────────────────┐
                    │    NORMAL_OPERATION    │◄────────────────┐
                    │  (NVMe block device    │                 │
                    │   fully enumerated)    │                 │
                    └────┬───────────────────┘                 │
                         │                                     │
          ┌──────────────┼──────────────────────┐             │
          │              │                      │             │
   PCIe D3hot/     V_in < 2.9V           Cache_full          │
   D3cold signal   interrupt             (write pressure)     │
          │              │                      │             │
          ▼              ▼                      ▼             │
  ┌──────────────┐ ┌────────────────┐  ┌────────────────┐    │
  │  GRACEFUL_  │ │ PANIC_FLUSH    │  │  THROTTLE_    │    │
  │  SHUTDOWN   │ │ (supercap      │  │  WRITEBACK    │    │
  │  (ordered   │ │  powered DMA   │  │  (background  │    │
  │   flush)    │ │  burst)        │  │  eMMC drain)  │────┘
  └─────────────┘ └────────────────┘  └────────────────┘
```

### 3.2 State: INIT_SEQUENCE

On power application, the PMIC sequences rails and the FPGA/ASIC firmware executes:

1. **Cartridge detection:** Poll mezzanine I²C for EEPROM ACK. If no ACK within 100 ms → assert `DEVICE_FAULT` NVMe error; enumerate as failed device.
2. **eMMC mount:** Initialize eMMC 5.1 in HS400 mode. Locate the most recent valid snapshot via CRC32-verified header blocks.
3. **LPDDR4 hydration:** DMA transfer of last valid snapshot from eMMC to LPDDR4. This constitutes the "disk contents" the OS will see. Transfer rate: ~300 MB/s (eMMC-limited); 32 GB hydration time ≈ 107 seconds worst case (acceptable at boot).
4. **NVMe enumeration:** Assert PCIe link training. Present NVMe 1.4 compliant namespace to host OS. Report device capacity = LPDDR4 installed capacity. Report media type = "Non-Volatile Memory" (the host need not know about the DRAM backing).
5. **Background writeback daemon start:** Firmware initializes a continuous low-priority DMA thread that mirrors dirty LPDDR4 pages to eMMC at ≤ 50 MB/s, preserving foreground bandwidth.

### 3.3 State: NORMAL_OPERATION

**Read path:**
```
Host PCIe read request → NVMe command queue → FPGA/ASIC DMA engine 
→ LPDDR4 read (< 100 ns latency) → PCIe completion TLP → Host
```

**Write path:**
```
Host PCIe write request → NVMe command queue → FPGA/ASIC DMA engine
→ LPDDR4 write (< 100 ns latency) → NVMe completion posted to host
→ [background] Dirty page flagged → Background writeback queue
```

**Performance targets (V1.0, PCIe Gen 3 × 4):**

| Metric | Target | Bottleneck |
|---|---|---|
| Sequential Read | 3,500 MB/s | PCIe Gen 3 × 4 bandwidth ceiling |
| Sequential Write | 3,300 MB/s | PCIe Gen 3 × 4 bandwidth ceiling |
| Random 4K Read (QD32) | 800K IOPS | FPGA NVMe queue engine |
| Random 4K Write (QD32) | 750K IOPS | FPGA NVMe queue engine |
| Write latency (99th pct) | < 20 µs | DRAM access time |

### 3.4 State: GRACEFUL_SHUTDOWN

Triggered by host OS issuing PCIe power state transition from **D0 → D3hot → D3cold** (standard OS shutdown/hibernate path).

**Shutdown sequence:**

1. FPGA/ASIC receives `D3hot` transition command via PCIe PM capability register
2. NVMe I/O queues are drained (all in-flight commands completed or aborted with retry)
3. LPDDR4 dirty page bitmap is finalized
4. Full LPDDR4 → eMMC DMA flush initiated (up to 107 seconds; host OS granted extended power-off timeout via NVMe `Power State Descriptor` with `ENLAT`/`EXLAT` values set appropriately)
5. eMMC snapshot header written with CRC32 checksum, timestamp, and dirty-page manifest
6. PCIe link enters L2/L3 ready state; PMIC powers down LPDDR4 arrays

**Incremental shutdown optimization:** The background writeback in NORMAL_OPERATION continuously reduces the dirty window. In steady-state, a graceful shutdown typically flushes only the last 2–5 GB of dirty data, completing in 7–17 seconds rather than the 107-second worst case.

### 3.5 State: PANIC_FLUSH (Ungraceful Power Loss)

Triggered by hardware interrupt when **V_in drops below 2.9 V** — indicating imminent loss of host 3.3V M.2 supply.

**Panic sequence (must complete before supercapacitors discharge below V_cutoff = 1.8 V):**

```
T = 0 µs:    PMIC comparator fires; interrupt asserted to FPGA/ASIC
T < 5 µs:    FPGA load switch isolates M.2 PCIe bus from host (prevents host 
             from seeing corrupted completions)
T < 10 µs:   PMIC switches power source from host 3.3V rail to supercapacitor 
             discharge path
T < 100 µs:  FPGA/ASIC aborts all in-flight NVMe I/O; freezes LPDDR4 write 
             access; marks current LPDDR4 state as "panic snapshot"
T < 500 µs:  eMMC brought to active write state (CMD24/CMD25 pre-issued)
T < 500 ms   DMA engine begins high-speed LPDDR4 → eMMC burst transfer of dirty
to ~50 s:    pages, prioritized by recency (most recently written pages first)
T = flush    eMMC snapshot header committed; PMIC enters low-power hold state;
   complete: LPDDR4 refresh disabled; system halts cleanly
```

**Supercapacitor energy budget validation:**

```
Available energy:  E = ½ × 44F × (3.3² - 1.8²) = ½ × 44 × 7.65 = 168.3 J
Required energy:   E = 3.0 W × 50 s = 150 J
Margin:            18.3 J (12.2% headroom — acceptable for production)
```

**Data safety guarantee:** Under the panic flush, data written to the device more than 5 seconds prior to the power event is guaranteed preserved (already in eMMC via background writeback). Data written in the last 0–5 seconds is flushed from LPDDR4 to eMMC during the panic sequence. **The device provides equivalent data durability to a battery-backed RAID controller.**

---

## 4. Firmware & Smart Caching Software Stack

### 4.1 Low-Level Firmware (Base Board FPGA/ASIC)

**Language:** Rust (bare-metal, `no_std` environment), targeting the FPGA softcore (RISC-V RV32IMC) responsible for command processing, with performance-critical DMA paths implemented as hardened RTL state machines (not soft CPU code).

**Architecture rationale for Rust:**

- Memory safety eliminates buffer overruns in the NVMe command parser — a historically common source of storage firmware vulnerabilities
- Zero-cost abstractions allow high-level state machine expression without runtime overhead
- `embedded-hal` trait ecosystem provides portable I²C, SPI, and eMMC driver interfaces
- Deterministic panic behavior (via `panic = "abort"`) is critical for the PANIC_FLUSH state — no heap allocator, no dynamic dispatch in the interrupt path

**Firmware modules:**

| Module | Implementation | Notes |
|---|---|---|
| `nvme_cmd_parser` | Rust + hardened RTL | NVMe 1.4 Admin + I/O command sets |
| `lpddr4_phy_ctrl` | RTL (FPGA) / hardened (ASIC) | Critical timing path; not soft-CPU suitable |
| `emmc_driver` | Rust (`no_std`) | eMMC 5.1 HS400; full error recovery |
| `dma_engine` | RTL + Rust control plane | Scatter-gather DMA list processing |
| `pmic_monitor` | Rust interrupt handler | V_in polling + panic trigger |
| `writeback_sched` | Rust async task | Background dirty-page drain |
| `cartridge_mgr` | Rust | I²C EEPROM read/write; wear tracking |
| `nvme_log_pages` | Rust | Vendor-specific log pages for daemon |

**Interrupt latency budget (PANIC_FLUSH path):**

The path from PMIC comparator fire to PCIe bus isolation is the most timing-critical segment. With FPGA fabric operating at 100 MHz (10 ns per cycle), the hardware interrupt → GPIO response path must be ≤ 50 cycles = 500 ns. This is achieved via:

- Dedicated hardware interrupt line (not polled via soft CPU)
- RTL state machine handles isolation switch — no soft CPU involvement
- PMIC comparator output connected directly to FPGA interrupt pin with Schmitt trigger conditioning

### 4.2 Host Daemon: InfinityCache Manager (ICM)

**Architecture:** A background system daemon written in Rust, with a cross-platform Tauri-based UI shell (Tauri provides native desktop UI with a Rust backend, WebView frontend, and small binary size — ideal for a utility application). Distributed as a single binary with no runtime dependencies.

**Platform support:**

| Platform | Daemon | UI | Auto-launch |
|---|---|---|---|
| Windows 10/11 | Windows Service | Tray icon + Tauri window | Registry `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` |
| macOS 12+ | launchd plist | Menu bar + Tauri window | `~/Library/LaunchAgents/` |
| Linux (systemd) | systemd unit | GTK tray + Tauri window | `systemd enable` |

#### 4.2.1 Smart Directory Detection & Soft-Link Engine

The ICM daemon continuously monitors filesystem activity using OS-native APIs:

- **Windows:** `ReadDirectoryChangesW` + VSS API for volume snapshot awareness
- **macOS:** `FSEvents` API
- **Linux:** `inotify` API

The daemon maintains a write-intensity heatmap per directory (rolling 7-day window). Directories exceeding a configurable write-intensity threshold (default: 500 MB/day) are flagged as candidates for **automatic soft-link migration** to the Infinity-Cache proxy volume.

**Auto-detected high-write directory patterns (V1.0 ruleset):**

| Category | Patterns | Typical Daily Write Volume |
|---|---|---|
| Node.js build | `node_modules/`, `.next/`, `dist/` | 2–20 GB |
| Rust/Cargo | `target/`, `~/.cargo/registry/` | 5–30 GB |
| CMake/Make | `build/`, `cmake-build-*/` | 3–15 GB |
| Adobe suite | `%TEMP%/Adobe/`, `~/Library/Caches/Adobe/` | 10–50 GB |
| DaVinci Resolve | Resolve scratch disk directory | 20–200 GB |
| Docker/OCI | `/var/lib/docker/overlay2/` | 5–40 GB |
| Python | `__pycache__/`, `.venv/`, `site-packages/` | 1–5 GB |
| Git LFS | `.git/lfs/` | 1–10 GB |

**Migration workflow:**

1. Daemon detects high-write directory `X` on primary NVMe SSD
2. ICM creates a mirrored path on the Infinity-Cache proxy volume
3. ICM atomically moves the directory contents to the proxy volume
4. ICM creates a filesystem symlink at `X` pointing to the proxy volume path
5. Host applications experience zero disruption — the path is unchanged from their perspective
6. ICM background sync ensures proxy contents are periodically replicated back to primary SSD for redundancy (configurable: sync frequency, sync on graceful shutdown only, or continuous)

#### 4.2.2 Performance Analytics Dashboard

The ICM UI provides real-time and historical visibility into:

- LPDDR4 dirty-page percentage (current volatile window at risk)
- eMMC endurance remaining (estimated years)
- Write bandwidth intercepted per application
- Estimated primary SSD lifespan extension (projected against original QLC DWPD rating)
- Panic flush event log (date, dirty volume at time of event, flush duration)

This dashboard serves both end-user value (tangible SSD lifespan savings) and indirect commercial value (continuous reinforcement of product efficacy → cartridge upgrade conversion).

#### 4.2.3 SaaS Subscription Tier — ICM Pro / ICM Teams

**Free tier (ICM Core):**
- Auto-detection and soft-link engine
- Single machine, local analytics
- Manual cartridge health reports
- Open-source daemon code (Apache 2.0)

**ICM Pro ($9.99/month or $79/year per seat):**
- Cross-machine sync of performance profiles (Docker volumes, build cache pre-warming)
- Cloud-backed cartridge health telemetry (opt-in)
- IDE integrations (VS Code extension, JetBrains plugin) surfacing real-time write intercept stats
- Priority firmware update channel

**ICM Teams ($29/month per seat, minimum 5 seats):**
- Centralized fleet dashboard for enterprise workstation management
- IT admin policy deployment (whitelist/blacklist auto-migration rules)
- NVMe log page aggregation → SIEM/Datadog integration
- Volume cartridge procurement portal with tiered pricing
- SLA-backed support

---

## 5. Commercialization, Unit Economics & Life Cycles

### 5.1 Target Bill of Materials (BOM)

#### Base Carrier Board (V1.0 FPGA Prototype)

| Component | Unit Cost (10K vol.) | Notes |
|---|---|---|
| Lattice ECP5-25F FPGA | $12.00 | Primary bridge; transitions to ASIC at V2.0 |
| Supercapacitors (2× 22F) | $4.50 | Vishay or Nichicon EDLC series |
| PMIC + load switches | $2.80 | TI or Analog Devices family |
| Mezzanine socket (base side) | $1.20 | Hirose DF40 or equivalent |
| PCB (4-layer, ENIG) | $2.50 | M.2 2280 with impedance control |
| Passives, decoupling, misc | $1.50 | |
| M.2 M-key edge connector | $0.80 | Gold-plated, 10,000 insertion cycles |
| **Total BOM** | **~$25.30** | **Target: sub-$30 at 10K; sub-$20 at 100K** |

> **ASIC transition at V2.0** replaces the $12 FPGA with a ~$6 custom ASIC, reducing base board BOM to ~$16 at 50K volume.

#### Memory Cartridge (V1.0 — 16 GB LPDDR4 + 32 GB eMMC)

| Component | Unit Cost (50K vol.) | Notes |
|---|---|---|
| LPDDR4 16 GB (FBGA-200) | $7.50 | Micron/Samsung spot pricing, 2026 est. |
| eMMC 32 GB (BGA-153) | $2.20 | Micron MTFC32G or equivalent |
| EEPROM 4 Kbit (SOT-23) | $0.15 | Microchip 24AA04 |
| Mezzanine plug (cartridge side) | $0.90 | Matching Hirose DF40 plug |
| PCB (2-layer) | $0.80 | Simpler board; 20 × 60 mm |
| Passives, misc | $0.45 | |
| **Total BOM** | **~$12.00** | **Target: sub-$15 retail-ready** |

### 5.2 Pricing Strategy & Margin Structure

| SKU | BOM | Manufacturer Cost | MSRP | Gross Margin |
|---|---|---|---|---|
| Base Carrier (V1.0 FPGA) | $25.30 | $28 (assembly + test) | $69 | ~60% |
| Base Carrier (V2.0 ASIC) | $16.00 | $18 | $59 | ~70% |
| Cartridge V1.0 (16 GB) | $12.00 | $13.50 | $34 | ~60% |
| Cartridge V2.0 (32 GB) | $16.00 | $18 | $49 | ~63% |
| Starter Bundle (Base + V1.0 Cart) | $37.30 | $41.50 | $89 | ~53% |

**Channel strategy:** Direct-to-consumer via branded webstore (highest margin) + Amazon/Newegg marketplace (volume, ~15% fee) + Micro Center retail partnership (brand legitimacy). B2B procurement via ICM Teams portal.

### 5.3 Revenue Model: Razor and Blade + SaaS

**Revenue stream decomposition (Year 3 projection, 100K active users):**

| Stream | Unit Economics | Annual Revenue Estimate |
|---|---|---|
| Base card hardware | $40 avg. margin × 40K new units/yr | $1.6M |
| Cartridge upgrades | $20 avg. margin × 60K units/yr | $1.2M |
| ICM Pro subscriptions | $79/yr × 15K subscribers | $1.19M |
| ICM Teams subscriptions | $29/seat/mo × 500 seats | $174K/yr |
| **Total** | | **~$4.16M ARR** |

**Unit economics are highly favorable:** The software SaaS layer requires near-zero incremental cost to serve at scale, making each new subscriber essentially pure margin above hosting costs (~$2/user/year for telemetry + sync infrastructure).

### 5.4 Cartridge Upgrade Lifecycle

The cartridge upgrade cycle is driven by **software data-density growth**, not chemical degradation — a fundamentally superior monetization driver:

- Docker image sizes: Growing at ~20% YoY (layer proliferation, AI model weights in containers)
- Node.js project sizes: `node_modules` directories of 2–5 GB per project are now standard
- Video editing scratch: 4K ProRes scratch files routinely require 200–400 GB per project

As the ICM daemon detects increasing write-cache pressure (LPDDR4 utilization > 80%), it proactively notifies the user and presents a cartridge upgrade CTA within the dashboard UI. The upgrade path is friction-minimal: order from the ICM portal, physically swap the cartridge (< 30 seconds), and the base board auto-detects and re-initializes with the higher-capacity cartridge. No data migration required — the background sync ensures eMMC vault is current before hot-swap.

---

## 6. Key Risks & Mitigations

### 6.1 Risk: Mechanical Stress on Mezzanine Connector

**Description:** The B2B mezzanine connector stack must withstand:
- M.2 screw clamping force (typically 0.5–0.8 N·m torque at M.2 retaining screw)
- Thermal cycling stress (connector CTE mismatch between FR4 PCBs and metal contacts)
- Vibration loads in workstation environments (HDD vibration crosstalk, fan vibration)

**Mitigation Strategy:**

1. **Connector selection:** Use a connector family with an integrated locking latch mechanism (e.g., Hirose DF40 with ZIF latch or Molex Easy-On with retention clip) to prevent vibration-induced unmating
2. **PCB stiffener:** Add a 0.3 mm stainless steel stiffener plate to the cartridge PCB aligned with the connector footprint to prevent PCB flex under clamping
3. **Underfill epoxy:** Apply low-modulus underfill (e.g., Loctite 3542) at the connector-to-PCB interface during assembly to distribute stress across the solder joint array
4. **Compliance testing:** Perform IEC 60068-2-6 (Vibration) and IEC 60068-2-14 (Thermal Shock) qualification testing on 100 pre-production assemblies prior to V1.0 launch
5. **Connector mating cycle margin:** The 30-cycle rated mating life of target connectors vs. expected 5–10 cartridge swaps per user over device lifetime provides a 3–6× safety factor

### 6.2 Risk: Thermal Throttling

**Description:** The M.2 2280 footprint co-locates an NVMe bridge (FPGA at 1–2 W; ASIC at 0.5 W), LPDDR4 array (~1.5 W active), and PMIC (~0.2 W) in a confined space with limited thermal mass and airflow.

**Thermal budget analysis:**

```
Total TDP (worst case):  FPGA 2W + LPDDR4 1.5W + eMMC 0.8W + PMIC 0.2W = 4.5W
M.2 PCIe adapter card:   Forced airflow from chassis fans typically provides 
                         15–25 LFM across PCIe slot area
Thermal resistance:      FR4 PCB to ambient: ~40°C/W (no heatspreader)
                         With aluminum M.2 heatspreader: ~15°C/W
Temperature rise:        No heatspreader: 4.5W × 40°C/W = 180°C rise (unacceptable)
                         With heatspreader: 4.5W × 15°C/W = 67.5°C rise above ambient
                         At 25°C ambient: 92.5°C — within LPDDR4 85°C max spec limit 
                         by <7°C margin
```

**Mitigation Strategy:**

1. **Mandatory M.2 heatspreader:** Ship the base carrier board with an adhesive aluminum heatspreader covering the FPGA and LPDDR4 areas. This is standard practice for high-performance M.2 drives
2. **Thermal interface material (TIM):** Use phase-change TIM (e.g., Bergquist GP3000) at heatspreader-to-component interface for <0.1°C·cm²/W thermal resistance
3. **FPGA dynamic power gating:** Implement aggressive clock gating in FPGA fabric during idle periods to reduce dynamic power from 2W to ~0.3W when host I/O is inactive
4. **ASIC V2.0 thermal improvement:** Custom ASIC at 22nm targets 0.5W TDP, reducing total device TDP to ~3W and providing >20°C additional thermal headroom
5. **Thermal throttle firmware:** FPGA/ASIC firmware reads an on-die temperature sensor and issues NVMe `Throttle` responses to the host if junction temperature exceeds 80°C, cleanly signaling the OS to reduce I/O pressure

### 6.3 Risk: Cache Exhaustion (Write Pressure Exceeding LPDDR4 Capacity)

**Description:** If an operating system write stream exceeds the installed LPDDR4 capacity before the background writeback daemon can drain dirty pages to eMMC, the device faces cache exhaustion — it cannot accept new writes.

**Exhaustion scenario analysis:**

```
V1.0 cartridge:      16 GB LPDDR4
Background writeback: 50 MB/s sustained to eMMC
Incoming write rate: X MB/s from host

Steady-state dirty window = (X - 50) MB/s × time
Exhaustion time at X = 3,000 MB/s sustained: Approx 5.5 seconds to fill 16 GB
(Note: 3 GB/s sustained sequential is an extreme sustained workload; 
 typical professional workloads sustain 500–1,500 MB/s average)
```

**Mitigation Strategy (layered):**

1. **Background writeback acceleration:** During high write-pressure episodes, the firmware can increase eMMC writeback from 50 MB/s to 200 MB/s by pre-empting read bandwidth, buying additional drain capacity

2. **Host throttling via NVMe `NSSRO` bit:** NVMe 1.4 spec defines a mechanism for devices to signal the host to reduce submission queue depth, effectively implementing back-pressure. The firmware sets the `NS Specific` throttling bit in completion entries when LPDDR4 utilization exceeds 90%

3. **NVMe `Power State` escalation:** The device can signal the host to transition to a lower write-bandwidth power state, which most NVMe drivers honor within 50–100 ms

4. **Graceful spill path (V1.1 feature):** If the host mounts a secondary NVMe SSD alongside the proxy, the ICM daemon can automatically redirect overflow writes to the secondary drive via a filesystem-level union mount, eliminating any user-visible stall

5. **Cartridge upgrade prompting:** When the ICM daemon detects that the user's workload regularly saturates the installed cartridge capacity, it displays a proactive upgrade notification. This converts a negative user experience (throttling) into a purchase conversion event

6. **V2.0 32 GB cartridge doubles the window:** At 32 GB, even a sustained 3 GB/s write stream takes ~11 seconds to saturate — sufficient for the eMMC writeback to compensate in all but the most extreme edge cases (large file overwrites of > 32 GB)

---

## 7. Appendices

### Appendix A: Open-Source Hardware Commitment

The following artifacts will be published under **CERN Open Hardware Licence v2 (Strongly Reciprocal)**:

- KiCad PCB design files for both base carrier board and memory cartridge
- Gerber manufacturing files and BOM with Manufacturer Part Numbers (MPNs)
- FPGA RTL source (Verilog + Rust-HDL) for NVMe bridge and DMA engine
- Firmware Rust source under MIT license

The ICM daemon core (detection engine, soft-link manager, analytics backend) will be published under **Apache 2.0**. The ICM Pro/Teams cloud sync features remain closed-source as the commercial moat.

**Open-source strategy rationale:** Open hardware accelerates third-party validation, community firmware contributions, and academic research partnerships. It also provides a credible defense against incumbent storage vendors attempting to block the product via patent enforcement — community prior art is established rapidly once HDL sources are public.

### Appendix B: Competitive Patent Landscape

Key patent zones to navigate:

- Samsung US10503428B2: DRAM-as-storage with power-loss protection (review claims carefully; our architecture may fall within method claims)
- Western Digital US10614017B2: Write buffer management with host throttling signaling
- Micron US10725898B2: Hybrid DRAM/NVM with background flush scheduling

**Recommended action:** Engage IP counsel to file provisional patents on:
1. The specific split-board mezzanine architecture for M.2 form factor
2. The software-driven cartridge upgrade triggering mechanism
3. The supercapacitor-powered panic flush state machine with dirty-window prioritization

### Appendix C: Key Milestones & Development Roadmap

| Milestone | Target Date | Deliverable |
|---|---|---|
| M0: Architecture freeze | Month 1 | This PRD approved; mezzanine connector selected |
| M1: PCB prototypes ordered | Month 2 | KiCad design complete; Gerbers to PCB fab |
| M2: FPGA bring-up | Month 3–4 | PCIe enumeration on FPGA; LPDDR4 read/write |
| M3: eMMC integration | Month 4–5 | Graceful shutdown flush working end-to-end |
| M4: Panic flush validation | Month 5–6 | Power-loss test bench; supercap energy validation |
| M5: ICM daemon alpha | Month 5–7 | Directory detection + soft-link on macOS/Linux |
| M6: Beta hardware (50 units) | Month 8 | External beta program; thermal + vibration testing |
| M7: FCC/CE certification | Month 9–10 | Regulatory filings; EMI pre-scan |
| M8: V1.0 crowdfunding launch | Month 10–11 | Kickstarter/Crowd Supply campaign |
| M9: V1.0 production | Month 13–14 | 5,000-unit first production run |
| M10: ASIC tape-out initiation | Month 14 | V2.0 ASIC NRE engagement; 22nm shuttle |

### Appendix D: Glossary

| Term | Definition |
|---|---|
| DWPD | Drive Writes Per Day — endurance metric representing how many times the full drive capacity can be written per day over the warranty period |
| eMMC | Embedded MultiMediaCard — a BGA-packaged flash storage standard (JEDEC JESD84); versions 4.5 through 5.1 support HS400 (400 MB/s) bus mode |
| EDLC | Electrical Double-Layer Capacitor (supercapacitor) — energy storage device with much higher capacitance than electrolytic capacitors; no electrochemical degradation under charge/discharge cycling |
| FPGA | Field-Programmable Gate Array — reconfigurable silicon fabric; used here for PCIe/NVMe/LPDDR4 bridging during prototyping phase |
| LPDDR4 | Low Power Double Data Rate 4 — DRAM standard (JEDEC JESD209-4); standard for mobile/embedded applications; volatile (requires continuous power and refresh cycles) |
| Mezzanine connector | A board-to-board connector pair that mechanically and electrically couples two parallel PCBs at a defined height offset |
| NVMe | Non-Volatile Memory Express — PCIe-native host controller interface (HCI) specification for solid-state storage devices |
| P/E cycle | Program/Erase cycle — one write-then-erase operation on a NAND flash cell; the primary lifetime-limiting mechanism for flash storage |
| PMIC | Power Management Integrated Circuit — manages voltage regulation, sequencing, monitoring, and protection functions |
| QLC | Quad-Level Cell — NAND flash cell storing 4 bits; lowest cost per GB but lowest endurance (~100–150 P/E cycles vs. 3,000 for MLC) |
| TLP | Transaction Layer Packet — the fundamental data transfer unit in PCIe |
| TIM | Thermal Interface Material — thermally conductive compound or pad placed between a heat source and heatsink |

---

*End of Document — Project Infinity-Cache Proxy PRD v1.0*

*For investment inquiries, hardware partnership discussions, or engineering recruitment, contact the project team via the open-source repository issue tracker.*

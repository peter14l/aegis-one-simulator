// Copyright (c) 2026 Aegis-One Storage Architecture Group. All rights reserved.
// This source code is proprietary and licensed under the Aegis-One Commercial Evaluation License (see LICENSE_EVALUATION.md).
// Unauthorized copying, modification, or distribution of this file is strictly prohibited.

// Aegis-Alpha Silicon Controller Architecture V3.0 (Elastic HMB Edition)
// Target: TSMC 22nm ULP / ASIC
// Role: High-Speed NVMe 2.0 to 4-Channel UFS 4.0 Array with Elastic HMB DMA

module aegis_alpha_top (
    // Host Interface (PCIe Gen4 x4)
    input  wire        pcie_clk,
    input  wire [3:0]  pcie_rx_p,
    input  wire [3:0]  pcie_rx_n,
    output wire [3:0]  pcie_tx_p,
    output wire [3:0]  pcie_tx_n,

    // Execution Tier (Elastic HMB - Host Memory Buffer via DMA)
    // No physical DRAM pins on PCB. ASIC borrows system RAM.
    output wire [63:0] hmb_dma_addr,
    output wire [31:0] hmb_dma_len,
    output wire        hmb_dma_rd_en,
    output wire        hmb_dma_wr_en,
    input  wire [63:0] hmb_dma_data_in,
    input  wire        hmb_dma_ready,

    // Persistence Tier (4x UFS 4.0 Channels - RAID-0 / Asynchronous)
    output wire        ufs0_tx_p, ufs0_tx_n, input wire ufs0_busy,
    output wire        ufs1_tx_p, ufs1_tx_n, input wire ufs1_busy,
    output wire        ufs2_tx_p, ufs2_tx_n, input wire ufs2_busy,
    output wire        ufs3_tx_p, ufs3_tx_n, input wire ufs3_busy,

    // Safety Tier (Host-Managed PLP via NVMe PLN)
    input  wire        nvme_pln_n,     // NVMe Power Loss Notification (Active LOW)
    input  wire        acpi_flush_en,  // Host-triggered ACPI emergency flush
    output wire        status_safe     // ASIC heartbeat: data committed to UFS
);

    // 1. NVMe 2.0 HMB DMA Engine
    // Manages the mapping between NVMe LBAs and Host Memory Pages.
    // Implements the "Elastic" logic to resize buffer based on host memory pressure.
    hmb_dma_engine u_hmb (
        .clk(pcie_clk),
        .addr_out(hmb_dma_addr),
        .rd_en(hmb_dma_rd_en),
        .data_in(hmb_dma_data_in)
        // ...
    );

    // 2. 4-Channel Asynchronous UFS Persistence Engine
    // Append-only log routing across 4 chips to mask GC latency and BKOPS.
    // Supports Pseudo-SLC fallback mode when HMB pressure is high.
    ufs_async_persistence u_persistence (
        .clk(pcie_clk),
        .data_in(hmb_dma_data_in),
        .ufs0_tx_p(ufs0_tx_p), .ufs0_busy(ufs0_busy),
        .ufs1_tx_p(ufs1_tx_p), .ufs1_busy(ufs1_busy),
        .ufs2_tx_p(ufs2_tx_p), .ufs2_busy(ufs2_busy),
        .ufs3_tx_p(ufs3_tx_p), .ufs3_busy(ufs3_busy)
    );

    // 3. Host-Managed Flush FSM
    // Replaces the old Tantalum-capacitor panic logic.
    // Listens for NVMe PLN and flushes dirty HMB pages to UFS using host standby power.
    panic_flush_fsm u_panic (
        .trigger(nvme_pln_n == 1'b0 || acpi_flush_en),
        .src_select(hmb_bus),
        .dst_select(ufs_array_bus),
        .safe_out(status_safe)
    );

endmodule

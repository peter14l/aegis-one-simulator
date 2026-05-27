// panic_flush_fsm.v
// Aegis-Alpha Phase 3: Host-Managed Emergency Persistence Handler
// Triggers on NVMe PLN or ACPI_FLUSH and flushes dirty HMB pages to UFS.

module panic_flush_fsm (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        trigger,          // High if NVMe Power Loss Notification active
    output reg         safe_out,         // Logic HIGH when all dirty pages are in UFS
    output reg [3:0]   state,
    
    // HMB DMA Interface
    output reg         hmb_rd_en,
    output reg [63:0]  hmb_addr,
    
    // UFS Persistence Interface
    output reg         ufs_wr_en,
    output reg [31:0]  ufs_addr
);

    // State Encoding
    localparam IDLE         = 4'd0;
    localparam FETCH_HMB    = 4'd1;
    localparam COMMIT_UFS   = 4'd2;
    localparam UPDATE_MAP   = 4'd3;
    localparam SHUTDOWN     = 4'd4;

    // Simulation limit for 16GB HMB address space
    localparam HMB_MAX_ADDR = 64'h0000000400000000; 

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            safe_out <= 1'b1;
            hmb_rd_en <= 1'b0;
            ufs_wr_en <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (trigger) begin
                        state <= FETCH_HMB;
                        safe_out <= 1'b0;
                        hmb_addr <= 64'h0;
                    end
                end

                FETCH_HMB: begin
                    hmb_rd_en <= 1'b1;
                    // Logic to read dirty page list from host RAM
                    // (Abstracted for silicon specification)
                    state <= COMMIT_UFS;
                end

                COMMIT_UFS: begin
                    ufs_wr_en <= 1'b1;
                    if (hmb_addr >= HMB_MAX_ADDR) begin
                        state <= SHUTDOWN;
                    end else begin
                        hmb_addr <= hmb_addr + 64'h1000;
                        ufs_addr <= ufs_addr + 32'h1000;
                        state <= FETCH_HMB;
                    end
                end

                SHUTDOWN: begin
                    safe_out <= 1'b1;
                    hmb_rd_en <= 1'b0;
                    ufs_wr_en <= 1'b0;
                    state <= SHUTDOWN; // Await total power loss
                end
            endcase
        end
    end

endmodule

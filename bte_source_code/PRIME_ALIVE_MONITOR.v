// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : PRIME_ALIVE_MONITOR.v
// Revision   : 1.0
// Modified   : 04/17/09
// Modified By: Mark Katsumura
// Changes    : (1) Initial Release
// =============================================================================
// *** Description ***
// =============================================================================
// The PRIME_ALIVE_MONITOR module
//
// (1) Monitors PRIME signals to check when asserted high
// (2) Monitors ALIVE signals to check when toggling healthy
// (3) Outputs data packets to FIFO when there is a state change 
//
// 10MHz CLK   = 100ns
// 5KHz ALIVE  = 200us
// =============================================================================
// *** TOC ***
// =============================================================================
// 0001.0 I/O Port Declaration
// 0001.1 Output Type Declaration
// 0002.0 Internal Nets Declaration
// 0003.0 Input Pipes
// 0004.0 Monitors
// 0005.0 State Changes
// 0006.0 FIFO
// xxxx.x Endmodule PRIME_ALIVE_MONITOR
// =============================================================================

`timescale  1 ns / 10 ps

module PRIME_ALIVE_MONITOR (
                // IN <-- UTILITY
                  CLK               
                , RESET
                , SYSTEM_TIME
                , SYSTEM_CSR
                
                // IN <-- MONITOR
                , PRIME
                , ALIVE
                
                // OUT --> STATUS
                , PRIME_STATUS
                , ALIVE_STATUS
                
                // IN <-- FIFO
                , PRIME_ALIVE_READ

                // OUT --> FIFO
                , PRIME_ALIVE_DATA
                , PRIME_ALIVE_EMPTY
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;
input  [31:0]   SYSTEM_TIME;
input  [31:0]   SYSTEM_CSR;

// IN <-- MONITOR
input  [1:0]    PRIME;
input  [1:0]    ALIVE;

// OUT --> STATUS
output [1:0]    PRIME_STATUS;
output [1:0]    ALIVE_STATUS;

// IN <-- FIFO
input           PRIME_ALIVE_READ;

// OUT --> FIFO
output [127:0]  PRIME_ALIVE_DATA;
output          PRIME_ALIVE_EMPTY;
 
// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> STATUS
wire   [1:0]    PRIME_STATUS;
wire   [1:0]    ALIVE_STATUS;

// OUT --> FIFO
wire   [127:0]  PRIME_ALIVE_DATA;
wire            PRIME_ALIVE_EMPTY;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [7:0]    prime_0_pipe;
reg    [7:0]    prime_1_pipe;
reg    [7:0]    alive_0_pipe;
reg    [7:0]    alive_1_pipe;

reg    [7:0]    sample_counter;
wire            sample;

reg    [3:0]    next_state;
reg    [3:0]    curr_state;

reg             state_change;
// wire   [31:0]   system_csr;

// -----------------------------------------------------------------------------
// 0003.0 Input Pipes
// -----------------------------------------------------------------------------

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        sample_counter  <= 0;
    else if (sample)    
        sample_counter  <= 0;
    else     
        sample_counter  <= sample_counter + 1;
end

assign sample = sample_counter == 10;
        
    
always @ (posedge CLK or posedge RESET) begin
    if (RESET) begin
        prime_0_pipe  <= 0;
        prime_1_pipe  <= 0;
        alive_0_pipe  <= 0;
        alive_1_pipe  <= 0;
    end    
    else begin
        prime_0_pipe  <= {prime_0_pipe[6:0], PRIME[0]};
        prime_1_pipe  <= {prime_1_pipe[6:0], PRIME[1]};
        alive_0_pipe  <= {alive_0_pipe[6:0], ALIVE[0]};
        alive_1_pipe  <= {alive_1_pipe[6:0], ALIVE[1]};
    end    
end

// -----------------------------------------------------------------------------
// 0004.0 Monitors
// -----------------------------------------------------------------------------

assign prime_0_status   = &(prime_0_pipe[7:3]);
assign prime_1_status   = &(prime_1_pipe[7:3]);

// The ALIVE signal is valid if toggling at 10us (so an edge every 5us)
// The PRIME signal is valid if high
// Both signals need some metastibility filtering.  But there should not be 
// need for any more filtering than that.  

ALIVE_FSM ALIVE_FSM_0 (
                // IN <-- UTILITY
                  .CLK                  (CLK)
                , .RESET                (RESET)
                
                // IN 
                , .ALIVE                (alive_0_pipe[7])
                
                // OUT
                , .ALIVE_STATUS         (alive_0_status)
                );

ALIVE_FSM ALIVE_FSM_1 (
                // IN <-- UTILITY
                  .CLK                  (CLK)
                , .RESET                (RESET)
                
                // IN 
                , .ALIVE                (alive_1_pipe[7])
                
                // OUT
                , .ALIVE_STATUS         (alive_1_status)
                );

// -----------------------------------------------------------------------------
// 0005.0 State Changes
// -----------------------------------------------------------------------------

always @ (*) begin
    next_state = {
                      prime_0_status
                    , prime_1_status
                    , alive_0_status
                    , alive_1_status
                    };
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        curr_state <= 0;
    else    
        curr_state <= next_state;
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        state_change <= 0;
    else    
        state_change <= curr_state != next_state;
end

// -----------------------------------------------------------------------------
// 0006.0 FIFO
// -----------------------------------------------------------------------------

// assign system_csr = {
//                       16'h2000              //  31:16
//                     , 8'h0                  //  15:8
//                     
//                     , 2'h0                  //   7:6
//                     , curr_state[2]         //   5
//                     , curr_state[3]         //   4
//                     
//                     , 2'h0                  //   3:2
//                     , curr_state[0]         //   1
//                     , curr_state[1]         //   0
//                     };

FIFO_128IN_128OUT_SMALL FIFO_128IN_128OUT_SMALL_0 (

                // UTILITY
            	  .clk              (CLK)
            	, .rst              (RESET)
                
                // IN
            	, .din              ({4'h2, SYSTEM_CSR[27:0], 32'hdead_beef, 32'hdead_beef, SYSTEM_TIME})
            	, .rd_en            (PRIME_ALIVE_READ)
            	, .wr_en            (state_change)
            	
            	// OUT
            	, .dout             (PRIME_ALIVE_DATA)
            	, .empty            (PRIME_ALIVE_EMPTY)
            	, .full             ( )
            	);
            	
// -----------------------------------------------------------------------------
// 0006.0 FIFO
// -----------------------------------------------------------------------------

assign PRIME_STATUS = {curr_state[2], curr_state[3]};
assign ALIVE_STATUS = {curr_state[0], curr_state[1]};

// -----------------------------------------------------------------------------
// xxxx.x Endmodule PRIME_ALIVE_MONITOR
// -----------------------------------------------------------------------------

endmodule










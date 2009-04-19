// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : UART.v
// Revision   : 1.0
// Modified   : 02/03/09
// Modified By: Mark Katsumura
// Changes    : (1) Initial Release
// =============================================================================
// *** Description ***
// =============================================================================
// The UART 
//
// (1) Accepts 64bit parallel data 
// (2) Transmits fixed protocol (start - 8bit - even parity - stop)
// (3) Parameterized speed based on 1us = 1MHz CLK
// (4) Parameterized interframe wait time (additional stop bits)
// =============================================================================
// *** TOC ***
// =============================================================================
// 0001.0 I/O Port Declaration
// 0001.1 Output Type Declaration
// 0002.0 Internal Nets Declaration
// xxxx.x Endmodule UART
// =============================================================================

`timescale  1 ns / 10 ps

module FIFO_ARBITER (
                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // IN <-- REQUESTORS
                , ERROR_FIFO_DATA
                , ERROR_FIFO_EMPTY
                , PRIME_ALIVE_FIFO_DATA
                , PRIME_ALIVE_FIFO_EMPTY
                , MONITOR_FIFO_DATA
                , MONITOR_FIFO_EMPTY
                
                // OUT --> REQUESTORS
                , ERROR_FIFO_READ
                , PRIME_ALIVE_FIFO_READ
                , MONITOR_FIFO_READ
                
                // OUT --> FIFO
                , FIFO_DATA
                , FIFO_WRITE
                
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// IN <-- REQUESTORS
input  [127:0]  ERROR_FIFO_DATA;
input           ERROR_FIFO_EMPTY;
input  [127:0]  PRIME_ALIVE_FIFO_DATA;
input           PRIME_ALIVE_FIFO_EMPTY;
input  [127:0]  MONITOR_FIFO_DATA;
input           MONITOR_FIFO_EMPTY;

// OUT --> REQUESTORS
output          ERROR_FIFO_READ;
output          PRIME_ALIVE_FIFO_READ;
output          MONITOR_FIFO_READ;
        
// OUT --> FIFO
output [127:0]  FIFO_DATA;
output          FIFO_WRITE;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> REQUESTORS
wire            ERROR_FIFO_READ;
wire            PRIME_ALIVE_FIFO_READ;
wire            MONITOR_FIFO_READ;

// OUT --> FIFO
reg    [127:0]  FIFO_DATA;
wire            FIFO_WRITE;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [2:0]    arb_sel;
reg    [2:0]    arb_sel_d1;

// -----------------------------------------------------------------------------
// 0003.0 FIFO
// -----------------------------------------------------------------------------

always @ (*) begin
    casex ({!PRIME_ALIVE_FIFO_EMPTY, !ERROR_FIFO_EMPTY, !MONITOR_FIFO_EMPTY})
        3'b1xx : arb_sel = 3'b100;
        3'b01x : arb_sel = 3'b010;
        3'b001 : arb_sel = 3'b001;
        3'b000 : arb_sel = 3'b000;
//         1xx: begin
//             ERROR_FIFO_READ         = 1;
//             PRIME_ALIVE_FIFO_READ   = 0;
//             MONITOR_FIFO_READ       = 0;
//         end
//         01x: begin
//             ERROR_FIFO_READ         = 0;
//             PRIME_ALIVE_FIFO_READ   = 1;
//             MONITOR_FIFO_READ       = 0;
//         end
//         001: begin
//             ERROR_FIFO_READ         = 0;
//             PRIME_ALIVE_FIFO_READ   = 0;
//             MONITOR_FIFO_READ       = 1;
//         end
//         000: begin
//             ERROR_FIFO_READ         = 0;
//             PRIME_ALIVE_FIFO_READ   = 0;
//             MONITOR_FIFO_READ       = 0;
//         end
    endcase
end
        
assign PRIME_ALIVE_FIFO_READ    = arb_sel[2];
assign ERROR_FIFO_READ          = arb_sel[1];
assign MONITOR_FIFO_READ        = arb_sel[0];


always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        arb_sel_d1 <= 0;
    else 
        arb_sel_d1 <= arb_sel;
end

always @ (*) begin
    case (arb_sel_d1)
        3'b100 : FIFO_DATA = PRIME_ALIVE_FIFO_DATA;
        3'b010 : FIFO_DATA = ERROR_FIFO_DATA;
        3'b001 : FIFO_DATA = MONITOR_FIFO_DATA;
        3'b000 : FIFO_DATA = 128'h0;
    endcase
end

assign FIFO_WRITE = |arb_sel_d1;



// -----------------------------------------------------------------------------
// xxxx.x Endmodule UART
// -----------------------------------------------------------------------------

endmodule


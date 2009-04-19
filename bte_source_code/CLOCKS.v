// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : ERROR.v
// Revision   : 1.0
// Modified   : 02/03/09
// Modified By: Mark Katsumura
// Changes    : (1) Initial Release
// =============================================================================
// *** Description ***
// =============================================================================
// The BTE 
// =============================================================================
// *** TOC ***
// =============================================================================
// 0001.0 I/O Port Declaration
// 0001.1 Output Type Declaration
// 0002.0 Internal Nets Declaration
// xxxx.x Endmodule ERROR
// =============================================================================

`timescale  1 ns / 10 ps

module CLOCKS (

                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // OUT --> CLOCKS
                , CLK_INT
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// OUT --> CLOCKS
output          CLK_INT;
 
// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> CLOCKS
wire            CLK_INT;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg             clk_div_50;
reg             clk_div_50_neg;
reg    [7:0]    clk_div_counter;
wire            clk_div_terminal_count;

// -----------------------------------------------------------------------------
// 0003.0 Timers
// -----------------------------------------------------------------------------

// The BTE will run at 10x of the CAN bus to give better resolution to the bus
// response times.  To generate this clock, the 50MHz onboard xtal is divided 
// by 50 and fed into a clock buffer.
//
// 50000000 / 1000000
// $ans = 50

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        clk_div_50  <= 0;
    else if (clk_div_terminal_count)
        clk_div_50  <= ~clk_div_50;
end

always @ (negedge CLK or posedge RESET) begin
    if (RESET)
        clk_div_50_neg  <= 0;
    else 
        clk_div_50_neg  <= clk_div_50;
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        clk_div_counter <= 0;
    else if (clk_div_terminal_count)
        clk_div_counter <= 0;
    else
        clk_div_counter <= clk_div_counter + 1;
end

// this commented clock is working with the UART as is at 230400 speed
// assign clk_div_terminal_count = clk_div_50 ? (clk_div_counter == 11) : (clk_div_counter == 12);
assign clk_div_terminal_count = clk_div_50 ? (clk_div_counter == 1) : (clk_div_counter == 2);
// assign clk_div_terminal_count = (clk_div_counter == 24); //clk_div_50 ? (clk_div_counter == 23) : (clk_div_counter == 24);

// BUFG bufg_0 (.I(clk_div_50), .O(clk_int));
// again this one was working with the UART
assign CLK_INT = clk_div_50 | clk_div_50_neg;
// assign CLK_INT = clk_div_50;

// -----------------------------------------------------------------------------
// xxxx.x Endmodule ERROR
// -----------------------------------------------------------------------------

endmodule

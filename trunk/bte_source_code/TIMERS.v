// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : TIMERS.v
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
// xxxx.x Endmodule TIMERS
// =============================================================================

`timescale  1 ns / 10 ps

module TIMERS (

                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // IN <-- CONTROL
                , START
                
                // OUT --> TIMERS
                , SYSTEM_TIME
                , PULSE_5MS
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// IN <-- CONTROL
input           START;
                
// OUT --> TIMERS
output [31:0]   SYSTEM_TIME;
output          PULSE_5MS;
 
// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> DEVICES
reg    [31:0]   SYSTEM_TIME;
reg             PULSE_5MS;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [31:0]   counter_5ms;
wire            counter_5ms_terminal_count;

// -----------------------------------------------------------------------------
// 0003.0 Timers
// -----------------------------------------------------------------------------

// Using CLK of 1us = 1MHz gives about an hour of unique system clock times

// pow(2,32) * 0.001 * 0.001 / 60 / 60
// $ans = 1.193046

// PULSE_5MS = 1clk pulse every 5ms (based on system clock)

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        SYSTEM_TIME <= 32'h0;
    else if (START)
        SYSTEM_TIME <= 32'h0;
    else 
        SYSTEM_TIME <= SYSTEM_TIME + 1;
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        counter_5ms <= 0;
    else if (START)    
        counter_5ms <= 0;
    else if (counter_5ms_terminal_count)
        counter_5ms <= 0;
    else
        counter_5ms <= counter_5ms + 1;
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        PULSE_5MS   <= 0;
    else if (counter_5ms_terminal_count)
        PULSE_5MS   <= 1;
    else    
        PULSE_5MS   <= 0;
end

assign counter_5ms_terminal_count = (counter_5ms == 49999);

// -----------------------------------------------------------------------------
// xxxx.x Endmodule TIMERS
// -----------------------------------------------------------------------------

endmodule

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
// (1) Accepts 64bit MONITOR_FIFO data 
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

module MONITOR_SHIFTER (
                // IN <-- UTILITY
                  CLK               
                , RESET
                , SYSTEM_TIME
                
                // IN <-- CONTROL
                , INHIBIT
                
                // IN <-- MONITOR
                , MONITOR_DATA
                , MONITOR_CLK
                
                // IN <-- FIFO
                , MONITOR_FIFO_READ
                
                // OUT --> FIFO
                , MONITOR_FIFO_DATA
                , MONITOR_FIFO_EMPTY
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;
input  [31:0]   SYSTEM_TIME;

// IN <-- CONTROL
input           INHIBIT;

// IN <-- MONITOR
input           MONITOR_DATA;
input           MONITOR_CLK;

// IN <-- FIFO
input           MONITOR_FIFO_READ;

// OUT --> FIFO
output [127:0]  MONITOR_FIFO_DATA;
output          MONITOR_FIFO_EMPTY;
 
// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> FIFO
reg    [127:0]  MONITOR_FIFO_DATA;
reg             MONITOR_FIFO_EMPTY;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [2:0]    monitor_data_delay;
reg    [2:0]    monitor_clk_delay;
reg    [95:0]   shifter;
reg    [7:0]    shifter_counter;
reg    [9:0]    shifter_watchdog; // 1K counter

wire            write_shifter;
wire            load_MONITOR_FIFO_data;

// -----------------------------------------------------------------------------
// 0003.0 SHIFTER
// -----------------------------------------------------------------------------

always @ (posedge CLK or posedge RESET) begin
    if (RESET) begin
        monitor_data_delay  <= 0;
        monitor_clk_delay   <= 0;
    end    
    else begin
        monitor_data_delay  <= {monitor_data_delay[1:0], MONITOR_DATA};
        monitor_clk_delay   <= {monitor_clk_delay[1:0], MONITOR_CLK};
    end    
end

assign write_shifter = INHIBIT ? 0 : (monitor_clk_delay[2:1]==2'b10) | (monitor_clk_delay[2:1]==2'b01);

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        shifter <= 96'h0;
    else if (write_shifter)
        shifter <= {shifter[94:0], monitor_data_delay[2]};
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        shifter_counter <= 0;
    else if (load_MONITOR_FIFO_data)    
        shifter_counter <= 0;
    else if (write_shifter)    
        shifter_counter <= shifter_counter + 1;
end

assign clear_watchdog = load_MONITOR_FIFO_data | write_shifter;

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        shifter_watchdog <= 0;
    else if (clear_watchdog)    
        shifter_watchdog <= 0;
    else if (shifter_counter!=0)    
        shifter_watchdog <= shifter_watchdog + 1;
end

assign load_MONITOR_FIFO_data = (shifter_counter == 96) | (shifter_watchdog == 1000);

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        MONITOR_FIFO_DATA   <= 128'h0;
    else if (load_MONITOR_FIFO_data)    
        MONITOR_FIFO_DATA   <= {shifter, SYSTEM_TIME};
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        MONITOR_FIFO_EMPTY  <= 1;
    else if (load_MONITOR_FIFO_data)
        MONITOR_FIFO_EMPTY  <= 0;
    else if (MONITOR_FIFO_READ)
        MONITOR_FIFO_EMPTY  <= 1;
end

// MONITOR_FIFO load the shifter into MONITOR_FIFO_DATA
// once MONITOR_FIFO_DATA is loaded, the shifter can acquire data again
// once the FIFO mux has accepted the data then the MONITOR_FIFO_DATA can be invalidated


// -----------------------------------------------------------------------------
// xxxx.x Endmodule UART
// -----------------------------------------------------------------------------

endmodule

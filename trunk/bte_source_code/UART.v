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

module UART (
                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // IN <-- FIFO
                , FIFO_DATA
                , FIFO_EMPTY
                
                // OUT --> FIFO
                , FIFO_READ
                
                // OUT --> COMPUTER
                , SERIAL
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// IN <-- FIFO
input  [7:0]    FIFO_DATA;
input           FIFO_EMPTY;

// OUT --> FIFO
output          FIFO_READ;

// OUT --> COMPUTER
output          SERIAL;
 
// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> FIFO
wire            FIFO_READ;

// OUT --> COMPUTER
wire            SERIAL;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

// BAUD_PERIOD is the clock count of 1us = 1MHz clocks
// A BAUD_PERIOD value of 1000 gives a 1ms = 1KHz baud rate

// Desired Period (us)
// (1 / 230400 * 1000000)
// $ans = 4.340278

// Desired Period / Tick Period
// (1 / 230400) / 0.0000001
// $ans = 43.402778

// Actual Speed for a count of 43
// 1 / (43 * 0.0000001)
// $ans = 232558.139535

// % Error (less than 1%)
// (230400 - 232558) / 230400 * 100
// $ans = -0.936632

parameter       BAUD_PERIOD         = 43;// 10MHz clk and 230400 speed 
parameter       INTERFRAME_WAIT     = 1;// results in packet of 1.815us for a 4DW packet + single ascii overhead

reg    [9:0]    data_shifter;
reg             fifo_read_d1;
reg             idle;

reg    [31:0]   baud_counter;
reg    [5:0]    total_counter;
wire            baud_counter_done;

wire   [9:0]    data_shifter_load_data;

// -----------------------------------------------------------------------------
// 0003.0 UART 
// -----------------------------------------------------------------------------

assign data_shifter_load_data = {
                                  1'b0
                                , FIFO_DATA[0]
                                , FIFO_DATA[1]
                                , FIFO_DATA[2]
                                , FIFO_DATA[3]
                                , FIFO_DATA[4]
                                , FIFO_DATA[5]
                                , FIFO_DATA[6]
                                , FIFO_DATA[7]
                                , 1'b1
                                };

assign baud_counter_done = (baud_counter == BAUD_PERIOD - 1);

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        baud_counter    <= 0;
    else if (baud_counter_done | FIFO_READ)
        baud_counter    <= 0;
    else     
        baud_counter    <= baud_counter + 1;
end
    
assign FIFO_READ = !FIFO_EMPTY & idle;

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        fifo_read_d1    <= 0;
    else
        fifo_read_d1    <= FIFO_READ;
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        data_shifter    <= 0;
    else if (fifo_read_d1) 
        data_shifter    <= data_shifter_load_data; //{1'b0, FIFO_DATA[0], FIFO_DATA[1], FIFO_DATA[2], FIFO_DATA[3], FIFO_DATA[4], FIFO_DATA[5], FIFO_DATA[6], FIFO_DATA[7], 2'b11};
    else if (baud_counter_done) 
        data_shifter    <= {data_shifter[8:0], 1'b1};
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        total_counter   <= 0;
    else if (FIFO_READ) 
        total_counter   <= 11 + INTERFRAME_WAIT;
    else if (baud_counter_done & (total_counter!=0)) 
        total_counter   <= total_counter - 1;
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        idle    <= 1;
    else if (FIFO_READ)
        idle    <= 0;
    else if (total_counter==0)
        idle    <= 1;
end    

assign SERIAL = data_shifter[9];

// parks low
// uart inverted
//
// exactly reversed bit order

// -----------------------------------------------------------------------------
// xxxx.x Endmodule UART
// -----------------------------------------------------------------------------

endmodule

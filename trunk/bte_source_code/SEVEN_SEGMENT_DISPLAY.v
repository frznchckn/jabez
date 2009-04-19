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

module SEVEN_SEGMENT_DISPLAY (
                // IN <-- UTILITY
                  CLK               
                , RESET
                , PULSE_5MS
                
                // IN <-- DIGIT HEX VALUES
                , DIGIT_0
                , DIGIT_1
                , DIGIT_2
                , DIGIT_3
                
                // OUT --> DISPLAY
                , SEVEN_SEGMENT
                , SEVEN_SEGMENT_ANODE
                
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;
input           PULSE_5MS;

// IN <-- FIFO
input  [3:0]    DIGIT_0;
input  [3:0]    DIGIT_1;
input  [3:0]    DIGIT_2;
input  [3:0]    DIGIT_3;

// OUT --> FIFO
output [7:0]    SEVEN_SEGMENT;
output [4:0]    SEVEN_SEGMENT_ANODE;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> FIFO
reg    [7:0]    SEVEN_SEGMENT;
reg    [4:0]    SEVEN_SEGMENT_ANODE;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [3:0]    digit_shifter;
wire   [7:0]    digit_0;
wire   [7:0]    digit_1;
wire   [7:0]    digit_2;
wire   [7:0]    digit_3;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

HEX_2_DIGIT HEX_2_DIGIT_0 (DIGIT_0, digit_0);
HEX_2_DIGIT HEX_2_DIGIT_1 (DIGIT_1, digit_1);
HEX_2_DIGIT HEX_2_DIGIT_2 (DIGIT_2, digit_2);
HEX_2_DIGIT HEX_2_DIGIT_3 (DIGIT_3, digit_3);

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        digit_shifter   <= 4'h1;
    else if (PULSE_5MS)
        digit_shifter   <= {digit_shifter[2:0], digit_shifter[3]};
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) begin
        SEVEN_SEGMENT       <= 8'h0;
        SEVEN_SEGMENT_ANODE <= 4'h0;
    end    
    else if (digit_shifter[0]) begin
        SEVEN_SEGMENT       <= ~digit_0;
        SEVEN_SEGMENT_ANODE <= 4'b1110;
    end
    else if (digit_shifter[1]) begin
        SEVEN_SEGMENT       <= ~digit_1;
        SEVEN_SEGMENT_ANODE <= 4'b1101;
    end
    else if (digit_shifter[2]) begin
        SEVEN_SEGMENT       <= ~digit_2;
        SEVEN_SEGMENT_ANODE <= 4'b1011;
    end
    else if (digit_shifter[3]) begin
        SEVEN_SEGMENT       <= ~digit_3;
        SEVEN_SEGMENT_ANODE <= 4'b0111;
    end
end    


// -----------------------------------------------------------------------------
// xxxx.x Endmodule UART
// -----------------------------------------------------------------------------

endmodule












// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

module HEX_2_DIGIT (
                // IN
                  HEX_IN
                // OUT
                , DIGIT_OUT
                );

input  [3:0]    HEX_IN;
output [7:0]    DIGIT_OUT;
reg    [7:0]    DIGIT_OUT;


always @ (*) begin
    case (HEX_IN)
        4'h0 :     DIGIT_OUT = 8'b0011_1111;
        4'h1 :     DIGIT_OUT = 8'b0000_0110;
        4'h2 :     DIGIT_OUT = 8'b0101_1011;
        4'h3 :     DIGIT_OUT = 8'b0100_1111;
        4'h4 :     DIGIT_OUT = 8'b0110_0110;
        4'h5 :     DIGIT_OUT = 8'b0110_1101;
        4'h6 :     DIGIT_OUT = 8'b0111_1101;
        4'h7 :     DIGIT_OUT = 8'b0000_0111;
        4'h8 :     DIGIT_OUT = 8'b0111_1111;
        4'h9 :     DIGIT_OUT = 8'b0110_0111;
        4'hA :     DIGIT_OUT = 8'b0110_0111;
        4'hB :     DIGIT_OUT = 8'b0111_1100;
        4'hC :     DIGIT_OUT = 8'b0111_1001;
        4'hD :     DIGIT_OUT = 8'b0101_1000;
        4'hE :     DIGIT_OUT = 8'b0111_1011;
        4'hF :     DIGIT_OUT = 8'b0111_0001;
    endcase
end    
endmodule
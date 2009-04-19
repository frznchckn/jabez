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

module FIFO_TO_ASCII (
                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // IN <-- FIFO
                , FIFO_DATA
                , FIFO_WRITE
                , ASCII_READ
                
                // OUT --> FIFO
                , ASCII_DATA
                , ASCII_EMPTY
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// IN <-- FIFO
input  [127:0]  FIFO_DATA;
input           FIFO_WRITE;
input           ASCII_READ;

// OUT --> FIFO
output [7:0]    ASCII_DATA;
output          ASCII_EMPTY;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> FIFO
wire   [7:0]    ASCII_DATA;
wire            ASCII_EMPTY;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [5:0]    nibble_counter; // 64 > 1 + 32 nibbles needed

reg    [7:0]    nibble_ascii;
reg    [3:0]    nibble_data;

wire   [127:0]  fifo_big_dout;
wire fifo_big_empty;
wire fifo_big_full;

// -----------------------------------------------------------------------------
// 0003.0 FIFO
// -----------------------------------------------------------------------------

assign fifo_big_read = ASCII_READ & (nibble_counter==0);

FIFO_128IN_128OUT FIFO_128IN_128OUT_0 (

                // UTILITY
            	  .clk           (CLK)
            	, .rst              (RESET)
                
                // IN
            	, .din              (FIFO_DATA)
            	, .rd_en            (fifo_big_read)
            	, .wr_en            (FIFO_WRITE)
            	
            	// OUT
            	, .dout             (fifo_big_dout)
            	, .empty            (fifo_big_empty)
            	, .full             (fifo_big_full)
            	);

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        nibble_counter    <= 0;
    else if (fifo_big_read)
        nibble_counter    <= 32;
    else if (ASCII_READ & (nibble_counter!=0))
        nibble_counter  <= nibble_counter - 1;
end

always @ (*) begin
    case (nibble_counter)
        0       : nibble_data = fifo_big_dout[3  :0  ];
        1       : nibble_data = fifo_big_dout[7  :4  ];
        2       : nibble_data = fifo_big_dout[11 :8  ];
        3       : nibble_data = fifo_big_dout[15 :12 ];
        4       : nibble_data = fifo_big_dout[19 :16 ];
        5       : nibble_data = fifo_big_dout[23 :20 ];
        6       : nibble_data = fifo_big_dout[27 :24 ];
        7       : nibble_data = fifo_big_dout[31 :28 ];
        8       : nibble_data = fifo_big_dout[35 :32 ];
        9       : nibble_data = fifo_big_dout[39 :36 ];
        10      : nibble_data = fifo_big_dout[43 :40 ];
        11      : nibble_data = fifo_big_dout[47 :44 ];
        12      : nibble_data = fifo_big_dout[51 :48 ];
        13      : nibble_data = fifo_big_dout[55 :52 ];
        14      : nibble_data = fifo_big_dout[59 :56 ];
        15      : nibble_data = fifo_big_dout[63 :60 ];
        16      : nibble_data = fifo_big_dout[67 :64 ];
        17      : nibble_data = fifo_big_dout[71 :68 ];
        18      : nibble_data = fifo_big_dout[75 :72 ];
        19      : nibble_data = fifo_big_dout[79 :76 ];
        20      : nibble_data = fifo_big_dout[83 :80 ];
        21      : nibble_data = fifo_big_dout[87 :84 ];
        22      : nibble_data = fifo_big_dout[91 :88 ];
        23      : nibble_data = fifo_big_dout[95 :92 ];
        24      : nibble_data = fifo_big_dout[99 :96 ];
        25      : nibble_data = fifo_big_dout[103:100];
        26      : nibble_data = fifo_big_dout[107:104];
        27      : nibble_data = fifo_big_dout[111:108];
        28      : nibble_data = fifo_big_dout[115:112];
        29      : nibble_data = fifo_big_dout[119:116];
        30      : nibble_data = fifo_big_dout[123:120];
        31      : nibble_data = fifo_big_dout[127:124];
    endcase                                      
end

always @ (*) begin
    case (nibble_data)
        0       : nibble_ascii = 8'h30;
        1       : nibble_ascii = 8'h31;
        2       : nibble_ascii = 8'h32;
        3       : nibble_ascii = 8'h33;
        4       : nibble_ascii = 8'h34;
        5       : nibble_ascii = 8'h35;
        6       : nibble_ascii = 8'h36;
        7       : nibble_ascii = 8'h37;
        8       : nibble_ascii = 8'h38;
        9       : nibble_ascii = 8'h39;
        10      : nibble_ascii = 8'h41;
        11      : nibble_ascii = 8'h42;
        12      : nibble_ascii = 8'h43;
        13      : nibble_ascii = 8'h44;
        14      : nibble_ascii = 8'h45;
        15      : nibble_ascii = 8'h46;
    endcase
end

assign ASCII_DATA = (nibble_counter==32) ? 8'h0A : nibble_ascii;
assign ASCII_EMPTY = fifo_big_empty & (nibble_counter==0);
                        
// -----------------------------------------------------------------------------
// xxxx.x Endmodule UART
// -----------------------------------------------------------------------------

endmodule


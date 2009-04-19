// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : ERROR.v
// Revision   : 1.0
// Modified   : 04/17/09
// Modified By: Mark Katsumura
// Changes    : (1) Initial Release
// =============================================================================
// *** Description ***
// =============================================================================
// The ERROR module
//
// (1) Inject errors into the system when the START button is pressed
// (2) Outputs data packets to FIFO when the error is injected
// =============================================================================
// *** TOC ***
// =============================================================================
// 0001.0 I/O Port Declaration
// 0001.1 Output Type Declaration
// 0002.0 Internal Nets Declaration
// 0003.0 ERROR Injection
// 0004.0 FIFO
// xxxx.x Endmodule ERROR
// =============================================================================

`timescale  1 ns / 10 ps

module ERROR (

                // IN <-- UTILITY
                  CLK               
                , RESET
                , SYSTEM_TIME
                
                // IN <-- TIMERS
                , PULSE_5MS
                
                // IN <-- FIFO ARBITER
                , ERROR_FIFO_READ
                
                // IN <-- CONTROL
                , START
                , ERROR_TARGET_SELECT
                , ERROR_TYPE_SELECT
                
                // OUT --> DEVICES
                , ERROR_TYPE_CONT_A
                , ERROR_TYPE_CONT_B
                , ERROR_TYPE_CONT_FDU
                
                // OUT --> FIFO
                , ERROR_FIFO_DATA
                , ERROR_FIFO_EMPTY
                , ERROR_FIFO_FULL
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;
input  [31:0]   SYSTEM_TIME;

// IN <-- TIMERS
input           PULSE_5MS;

// IN <-- FIFO ARBITER
input           ERROR_FIFO_READ;

// IN <-- CONTROL
input           START;
input  [1:0]    ERROR_TARGET_SELECT;
input  [3:0]    ERROR_TYPE_SELECT;
                
// OUT --> DEVICES
output [3:0]    ERROR_TYPE_CONT_A;
output [3:0]    ERROR_TYPE_CONT_B;
output [1:0]    ERROR_TYPE_CONT_FDU;
 
// OUT --> FIFO
output [31:0]   ERROR_FIFO_DATA;
output          ERROR_FIFO_EMPTY;
output          ERROR_FIFO_FULL;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> DEVICES
reg    [3:0]    ERROR_TYPE_CONT_A;
reg    [3:0]    ERROR_TYPE_CONT_B;
reg    [1:0]    ERROR_TYPE_CONT_FDU;

// OUT --> FIFO
wire   [127:0]  ERROR_FIFO_DATA;
wire            ERROR_FIFO_EMPTY;
wire            ERROR_FIFO_FULL;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg             start_d1;
wire            start_posedge;

reg             start_error;

wire   [31:0]   system_csr;

// -----------------------------------------------------------------------------
// 0003.0 ERROR Injection
// -----------------------------------------------------------------------------

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        start_d1    <= 0;
    else
        start_d1    <= START;
end

assign start_posedge = START & !start_d1;

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        start_error <= 0;
    else if (start_posedge)
        start_error <= 1;
    else if (PULSE_5MS)
        start_error <= 0;
end
        
always @ (*) begin
        casex ({start_error, ERROR_TARGET_SELECT})
            3'b0xx : begin
                ERROR_TYPE_CONT_A   <= 0;   
                ERROR_TYPE_CONT_B   <= 0;
                ERROR_TYPE_CONT_FDU <= 0;
            end
            3'b100 : begin
                ERROR_TYPE_CONT_A   <= ERROR_TYPE_SELECT;   
                ERROR_TYPE_CONT_B   <= 0;
                ERROR_TYPE_CONT_FDU <= 0;
            end
            3'b101 : begin
                ERROR_TYPE_CONT_A   <= 0;
                ERROR_TYPE_CONT_B   <= ERROR_TYPE_SELECT;   
                ERROR_TYPE_CONT_FDU <= 0;
            end
            3'b110 : begin
                ERROR_TYPE_CONT_A   <= 0;
                ERROR_TYPE_CONT_B   <= 0;   
                ERROR_TYPE_CONT_FDU <= 2'b01;
            end
            3'b111 : begin
                ERROR_TYPE_CONT_A   <= 0;
                ERROR_TYPE_CONT_B   <= 0;   
                ERROR_TYPE_CONT_FDU <= 2'b10;
            end
        endcase
end

// -----------------------------------------------------------------------------
// 0004.0 FIFO
// -----------------------------------------------------------------------------

assign system_csr = {
                      16'h1000              //  31:16
                    , 2'h0                  //  15:14
                    , ERROR_TARGET_SELECT   //  13:12
                    , ERROR_TYPE_SELECT     //  11:8
                    , 8'h00                 //   7:0
                    };

FIFO_128IN_128OUT_SMALL FIFO_128IN_128OUT_SMALL_0 (

                // UTILITY
            	  .clk              (CLK)
            	, .rst              (RESET)
                
                // IN
            	, .din              ({system_csr, 32'hdead_beef, 32'hdead_beef, SYSTEM_TIME})
            	, .rd_en            (ERROR_FIFO_READ)
            	, .wr_en            (start_posedge)
            	
            	// OUT
            	, .dout             (ERROR_FIFO_DATA)
            	, .empty            (ERROR_FIFO_EMPTY)
            	, .full             (ERROR_FIFO_FULL)
            	);

// -----------------------------------------------------------------------------
// xxxx.x Endmodule ERROR
// -----------------------------------------------------------------------------

endmodule

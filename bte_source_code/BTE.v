// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : BTE.v
// Revision   : 1.0
// Modified   : 04/17/09
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
// 0003.0 SWITCH ASSIGNMENTS
// 0004.0 LED ASSIGNMENTS
// 0005.0 SEVEN_SEGMENT_DISPLAY
// 0006.0 CLOCKS
// 0007.0 DEBOUNCERS
// 0008.0 TIMERS
// 0009.0 ERROR
// 0010.0 PRIME_ALIVE_MONITOR
// 0011.0 MONITOR
// 0012.0 FIFO Arbiter
// 0013.0 FIFO
// 0014.0 UART
// xxxx.x Endmodule BTE
// =============================================================================

`timescale  1 ns / 10 ps

module BTE (

                // IN <-- UTILITY
                  CLK               
                
                // IN <-- MONITOR
                , MONITOR_DATA
                , MONITOR_CLK
                
                // IN <-- FDU
                , PRIME
                
                // OUT --> FDU
                , ERROR_TYPE_CONT_FDU
                
                // IN <-- CONTROLLERS
                , ALIVE
                
                // OUT --> CONTROLLERS
                , ERROR_TYPE_CONT_A
                , ERROR_TYPE_CONT_B
                
                // OUT --> COMPUTER
                , SERIAL
                
                // OUT --> ONBOARD DEBUG
                , LED
                , SEVEN_SEGMENT
                , SEVEN_SEGMENT_ANODE
                
                // IN <-- BOARD DEBUG
                , SLIDE_SWITCH
                , PUSH_SWITCH
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
                
// IN <-- MONITOR
input           MONITOR_DATA;
input           MONITOR_CLK;

// IN <-- DEVICES
input  [1:0]    PRIME;
input  [1:0]    ALIVE;

// OUT --> DEVICES
output [3:0]    ERROR_TYPE_CONT_A;
output [3:0]    ERROR_TYPE_CONT_B;
output [1:0]    ERROR_TYPE_CONT_FDU;

// OUT --> COMPUTER
output          SERIAL;
 
// OUT --> ONBOARD DEBUG
output [7:0]    LED;
output [7:0]    SEVEN_SEGMENT;
output [3:0]    SEVEN_SEGMENT_ANODE;

// IN <-- BOARD DEBUG
input  [7:0]    SLIDE_SWITCH;
input  [3:0]    PUSH_SWITCH;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> DEVICES
wire   [3:0]    ERROR_TYPE_CONT_A;
wire   [3:0]    ERROR_TYPE_CONT_B;
wire   [1:0]    ERROR_TYPE_CONT_FDU;

// OUT --> COMPUTER
wire            SERIAL;

// OUT --> ONBOARD DEBUG
wire   [7:0]    LED;
wire   [7:0]    SEVEN_SEGMENT;
wire   [3:0]    SEVEN_SEGMENT_ANODE;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

// UTILITY
wire            clk_int;
wire   [31:0]   system_time;
wire            pulse_5ms;
wire            start_debounced;
wire   [31:0]   system_csr;

// Switches and Buttons
wire            RESET;
wire   [1:0]    ERROR_TARGET_SELECT;
wire   [3:0]    ERROR_TYPE_SELECT;
wire            START;
wire            INHIBIT;

// 
wire   [1:0]    prime_status;
wire   [1:0]    alive_status;

// FIFO wires
wire   [127:0]  error_fifo_data;
wire            error_fifo_empty;
wire            error_fifo_read;
wire            error_fifo_full;//!!! //??? is there any need for the full overrun signal???

wire   [127:0]  monitor_fifo_data;
wire            monitor_fifo_empty;
wire            monitor_fifo_read;

wire   [127:0]  prime_alive_fifo_data;
wire            prime_alive_fifo_empty;
wire            prime_alive_fifo_read;

wire   [127:0]  fifo_data;
wire            fifo_write;

wire   [7:0]    ascii_data;
wire            ascii_empty;
wire            ascii_read;

// -----------------------------------------------------------------------------
// 0003.0 SWITCH ASSIGNMENTS
// -----------------------------------------------------------------------------

assign RESET                = PUSH_SWITCH[3];

assign ERROR_TARGET_SELECT  = SLIDE_SWITCH[5:4];
assign ERROR_TYPE_SELECT    = SLIDE_SWITCH[3:0];

assign START                = PUSH_SWITCH[0];
assign INHIBIT              = SLIDE_SWITCH[7];

// -----------------------------------------------------------------------------
// 0004.0 LED ASSIGNMENTS
// -----------------------------------------------------------------------------

assign LED[0] = SLIDE_SWITCH[0];
assign LED[1] = SLIDE_SWITCH[1];
assign LED[2] = SLIDE_SWITCH[2];
assign LED[3] = SLIDE_SWITCH[3];
assign LED[4] = PRIME[1];
assign LED[5] = PRIME[0];
assign LED[6] = ALIVE[1];
assign LED[7] = ALIVE[0];

// all outputs to seven segment display are active low
// assign SEVEN_SEGMENT       = 8'h00;
// assign SEVEN_SEGMENT_ANODE = 4'hc;

// -----------------------------------------------------------------------------
// 0005.0 CSR Assignments
// -----------------------------------------------------------------------------

assign system_csr = {
                      16'h0000              //  31:16
                    , 2'h0                  //  15:14
                    , ERROR_TARGET_SELECT   //  13:12
                    , ERROR_TYPE_SELECT     //  11:8
                    , 2'h0                  //   7:6
                    , prime_status          //   5:4
                    , 2'h0                  //   3:2
                    , alive_status          //   1:0
                    };

// -----------------------------------------------------------------------------
// 0005.0 SEVEN_SEGMENT_DISPLAY
// -----------------------------------------------------------------------------

SEVEN_SEGMENT_DISPLAY SEVEN_SEGMENT_DISPLAY_0 (
                // IN <-- UTILITY
                  .CLK                      (CLK)               
                , .RESET                    (RESET)
                , .PULSE_5MS                (pulse_5ms)
                
                // IN <-- DIGIT HEX VALUES
                , .DIGIT_0                  (SLIDE_SWITCH[3:0])
                , .DIGIT_1                  (0)
                , .DIGIT_2                  ({2'h0, prime_status})
                , .DIGIT_3                  ({2'h0, alive_status})
                
                // OUT --> DISPLAY
                , .SEVEN_SEGMENT            (SEVEN_SEGMENT)
                , .SEVEN_SEGMENT_ANODE      (SEVEN_SEGMENT_ANODE)
                );

// -----------------------------------------------------------------------------
// 0006.0 CLOCKS
// -----------------------------------------------------------------------------

CLOCKS CLOCKS_0 (
                // IN <-- UTILITY
                  .CLK                      (CLK)               
                , .RESET                    (RESET)
                                            
                // OUT --> CLOCKS           
                , .CLK_INT                  (clk_int)
                );
                
// -----------------------------------------------------------------------------
// 0007.0 DEBOUNCERS
// -----------------------------------------------------------------------------

DEBOUNCER DEBOUNCER_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                                            
                // IN <-- TIMERS            
                , .PULSE_5MS                (pulse_5ms)
                                            
                // IN <-- BOUNCING          
                , .BOUNCING                 (START)
                                            
                // OUT --> DEBOUNCED        
                , .DEBOUNCED                (start_debounced)
                );
                
// -----------------------------------------------------------------------------
// 0008.0 TIMERS
// -----------------------------------------------------------------------------

TIMERS TIMERS_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                                            
                // IN <-- CONTROL           
                , .START                    (0)
                                            
                // OUT --> TIMERS           
                , .SYSTEM_TIME              (system_time)
                , .PULSE_5MS                (pulse_5ms)
                );

// -----------------------------------------------------------------------------
// 0009.0 ERROR
// -----------------------------------------------------------------------------

ERROR ERROR_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                , .SYSTEM_TIME              (system_time)
                , .SYSTEM_CSR               (system_csr)
                                            
                // IN <-- TIMERS            
                , .PULSE_5MS                (pulse_5ms)
                                            
                // IN <-- FIFO ARBITER      
                , .ERROR_FIFO_READ          (error_fifo_read)
                                            
                // IN <-- CONTROL           
                , .START                    (start_debounced)
                , .ERROR_TARGET_SELECT      (ERROR_TARGET_SELECT)
                , .ERROR_TYPE_SELECT        (ERROR_TYPE_SELECT)
                                            
                // OUT --> DEVICES          
                , .ERROR_TYPE_CONT_A        (ERROR_TYPE_CONT_A)
                , .ERROR_TYPE_CONT_B        (ERROR_TYPE_CONT_B)
                , .ERROR_TYPE_CONT_FDU      (ERROR_TYPE_CONT_FDU)
                                            
                // OUT --> FIFO             
                , .ERROR_FIFO_DATA          (error_fifo_data)
                , .ERROR_FIFO_EMPTY         (error_fifo_empty)
                , .ERROR_FIFO_FULL          (error_fifo_full)
                );
                
// -----------------------------------------------------------------------------
// 0010.0 PRIME_ALIVE_MONITOR
// -----------------------------------------------------------------------------

PRIME_ALIVE_MONITOR PRIME_ALIVE_MONITOR_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                , .SYSTEM_TIME              (system_time)
                , .SYSTEM_CSR               (system_csr)
                                            
                // IN <-- MONITOR           
                , .PRIME                    (PRIME)
                , .ALIVE                    (ALIVE)
                
                // OUT --> STATUS
                , .PRIME_STATUS             (prime_status)
                , .ALIVE_STATUS             (alive_status)
                                            
                // IN <-- FIFO              
                , .PRIME_ALIVE_READ         (prime_alive_fifo_read)
                                            
                // OUT --> FIFO             
                , .PRIME_ALIVE_DATA         (prime_alive_fifo_data)
                , .PRIME_ALIVE_EMPTY        (prime_alive_fifo_empty)
                );

// -----------------------------------------------------------------------------
// 0011.0 MONITOR
// -----------------------------------------------------------------------------

MONITOR_SHIFTER MONITOR_SHIFTER_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                , .SYSTEM_TIME              (system_time)
                                            
                // IN <-- CONTROL           
                , .INHIBIT                  (INHIBIT)
                                            
                // IN <-- MONITOR           
                , .MONITOR_DATA             (MONITOR_DATA)
                , .MONITOR_CLK              (MONITOR_CLK)
                                            
                // IN <-- FIFO              
                , .MONITOR_FIFO_READ        (monitor_fifo_read)
                                            
                // OUT --> FIFO             
                , .MONITOR_FIFO_DATA        (monitor_fifo_data)
                , .MONITOR_FIFO_EMPTY       (monitor_fifo_empty)
                );

// -----------------------------------------------------------------------------
// 0012.0 FIFO Arbiter
// -----------------------------------------------------------------------------

FIFO_ARBITER FIFO_ARBITER_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                
                // IN <-- REQUESTORS
                , .ERROR_FIFO_DATA          (error_fifo_data       )
                , .ERROR_FIFO_EMPTY         (error_fifo_empty      )
                , .PRIME_ALIVE_FIFO_DATA    (prime_alive_fifo_data )
                , .PRIME_ALIVE_FIFO_EMPTY   (prime_alive_fifo_empty)
                , .MONITOR_FIFO_DATA        (monitor_fifo_data     )
                , .MONITOR_FIFO_EMPTY       (monitor_fifo_empty    )
                                                                    
                // OUT --> REQUESTORS                               
                , .ERROR_FIFO_READ          (error_fifo_read      ) 
                , .PRIME_ALIVE_FIFO_READ    (prime_alive_fifo_read) 
                , .MONITOR_FIFO_READ        (monitor_fifo_read    ) 
                
                // OUT --> FIFO
                , .FIFO_DATA                (fifo_data)
                , .FIFO_WRITE               (fifo_write)
                );

// -----------------------------------------------------------------------------
// 0013.0 FIFO
// -----------------------------------------------------------------------------

FIFO_TO_ASCII FIFO_TO_ASCII_0 (
                // IN <-- UTILITY
                  .CLK                      (clk_int)               
                , .RESET                    (RESET)
                                            
                // IN <-- FIFO              
                , .FIFO_DATA                (fifo_data)
                , .FIFO_WRITE               (fifo_write)
                , .ASCII_READ               (ascii_read)
                                            
                // OUT --> FIFO             
                , .ASCII_DATA               (ascii_data)
                , .ASCII_EMPTY              (ascii_empty)
                );
                
// -----------------------------------------------------------------------------
// 0014.0 UART
// -----------------------------------------------------------------------------

UART UART_0 (
                // IN <-- UTILITY
                  .CLK              (clk_int)               
                , .RESET            (RESET)
                
                // IN <-- FIFO
                , .FIFO_DATA        (ascii_data)
                , .FIFO_EMPTY       (ascii_empty)
                
                // OUT --> FIFO
                , .FIFO_READ        (ascii_read)
                
                // OUT --> COMPUTER
                , .SERIAL           (SERIAL)
                );
                
// -----------------------------------------------------------------------------
// xxxx.x Endmodule BTE
// -----------------------------------------------------------------------------

endmodule

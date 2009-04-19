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

module ALIVE_FSM (
                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // IN 
                , ALIVE
                
                // OUT
                , ALIVE_STATUS
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// IN
input           ALIVE;

// OUT
output          ALIVE_STATUS;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

wire            ALIVE_STATUS;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [11:0]   alive_counter;
reg             stored_alive;


reg    [2:0]    next_state;
reg    [2:0]    curr_state;

parameter       ST_IDLE = 3'b001;
parameter       ST_LOW  = 3'b010;
parameter       ST_HIGH = 3'b100;

wire            posedge_detect;
wire            negedge_detect;
wire            timeout_alive;

// -----------------------------------------------------------------------------
// 0003.0 FSM
// -----------------------------------------------------------------------------

always @ (*) begin
    next_state = curr_state;
    
    case (curr_state)
    
        ST_IDLE : begin
            if (!stored_alive & posedge_detect)
                next_state = ST_HIGH;
            else if (stored_alive & negedge_detect)
                next_state = ST_LOW;
            else     
                next_state = ST_IDLE;
        end        
        
        ST_LOW : begin
            if (posedge_detect)
                next_state = ST_HIGH;
            else if (timeout_alive)    
                next_state = ST_IDLE;
            else 
                next_state = ST_LOW;
        end
                
        ST_HIGH : begin
            if (negedge_detect)
                next_state = ST_LOW;
            else if (timeout_alive)    
                next_state = ST_IDLE;
            else 
                next_state = ST_HIGH;
        end
        
    endcase
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        curr_state <= ST_IDLE;
    else 
        curr_state <= next_state;
end


assign ALIVE_STATUS = curr_state!=ST_IDLE;

// -----------------------------------------------------------------------------
// 0003.0 counters and detects
// -----------------------------------------------------------------------------

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        alive_counter <= 0;
    else if (curr_state==ST_IDLE)    
        alive_counter <= 0;
    else if (negedge_detect | posedge_detect)
        alive_counter <= 0;
    else
        alive_counter <= alive_counter + 1;
end

// assign timeout_alive = alive_counter == 550;
assign timeout_alive = alive_counter == 2000;

// 5KHz ALIVE = 200us
// timeout at 55us then

// 55000 / 100
// 200000 / 100
// $ans = 2000

always @ (posedge CLK or posedge RESET) begin
    if (RESET) 
        stored_alive <= 0;
    else if (curr_state==ST_IDLE)    
        stored_alive <= ALIVE;
    else begin    
        if (negedge_detect)    
            stored_alive <= 0;
        else if (posedge_detect)    
            stored_alive <= 1;
    end
end

assign posedge_detect = !stored_alive &  ALIVE;
assign negedge_detect =  stored_alive & !ALIVE;

// -----------------------------------------------------------------------------
// xxxx.x Endmodule UART
// -----------------------------------------------------------------------------

endmodule


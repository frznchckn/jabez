// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : DEBOUNCER.v
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

module DEBOUNCER (

                // IN <-- UTILITY
                  CLK               
                , RESET
                
                // IN <-- TIMERS
                , PULSE_5MS
                
                // IN <-- BOUNCING
                , BOUNCING
                
                // OUT --> DEBOUNCED
                , DEBOUNCED
                );
                
// -----------------------------------------------------------------------------
// 0001.0 I/O Port Declaration
// -----------------------------------------------------------------------------
                
// IN <-- UTILITY
input           CLK;
input           RESET;

// IN <-- TIMERS
input           PULSE_5MS;

// IN <-- BOUNCING
input           BOUNCING;

// OUT --> DEBOUNCED
output          DEBOUNCED;

// -------------------------------------
// 0001.1 Output Type Declaration
// -------------------------------------

// OUT --> DEBOUNCED
reg             DEBOUNCED;

// -----------------------------------------------------------------------------
// 0002.0 Internal Nets Declaration
// -----------------------------------------------------------------------------

reg    [4:0]    delay_bounce;

// -----------------------------------------------------------------------------
// 0003.0 Timers
// -----------------------------------------------------------------------------

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        delay_bounce    <= 0;
    else if (PULSE_5MS)
        delay_bounce    <= {delay_bounce[3:0], BOUNCING};
end

always @ (posedge CLK or posedge RESET) begin
    if (RESET)
        DEBOUNCED    <= 0;
    else if (delay_bounce==5'b11111)
        DEBOUNCED    <= 1;
    else if (delay_bounce==5'b00000)
        DEBOUNCED    <= 0;
end


// -----------------------------------------------------------------------------
// xxxx.x Endmodule ERROR
// -----------------------------------------------------------------------------

endmodule

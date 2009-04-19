// =============================================================================
// *** Revision History ***
// =============================================================================
// File       : BTE.v
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
// 0003.0 Instantiate FLSH_ARB
// 0004.0 Instantiate FLSH_NOR
// 0005.0 Instantiate FLSH_NAND
// xxxx.x Endmodule MCAM_FLSH
// =============================================================================

`timescale  1 ns / 10 ps

module BTE_tb;

// IN <-- UTILITY
reg             CLK;

// IN <-- SWITCHES
reg             MONITOR_DATA;
reg             MONITOR_CLK;

// IN <-- FDU
reg    [1:0]    PRIME;

// OUT --> FDU
wire   [1:0]    ERROR_TYPE_CONT_FDU;

// IN <-- CONTROLLERS
reg    [1:0]    ALIVE;

// OUT --> CONTROLLERS
wire   [3:0]    ERROR_TYPE_CONT_A;
wire   [3:0]    ERROR_TYPE_CONT_B;

// OUT --> COMPUTER
wire            SERIAL;

// OUT --> ONBOARD DEBUG
wire   [7:0]    LED;
wire   [7:0]    SEVEN_SEGMENT;
wire   [3:0]    SEVEN_SEGMENT_ANODE;

// IN <-- BOARD DEBUG
reg    [7:0]    SLIDE_SWITCH;
reg    [3:0]    PUSH_SWITCH;




integer         i;
integer         j;
integer         k;

parameter       ONE_US              = 1000;
parameter       ONE_MS              = (1000 * ONE_US);
parameter       ALIVE_PERIOD        = (100 * ONE_US);//100us
parameter       MONITOR_PERIOD      = (22 * ONE_US); //22us


// -----------------------------------------------------------------------------
// xxxx.x UTILITY
// -----------------------------------------------------------------------------

initial
    begin
        SLIDE_SWITCH    = 0;
        PUSH_SWITCH     = 0;
    end    

// CLK
initial
    begin
        CLK = 0;
        forever
            #10 CLK = ~CLK;//50 MHz = 20ns period
    end
    
// RST
initial
    begin
        PUSH_SWITCH[3] = 1;
        #100 PUSH_SWITCH[3] = 0; 
    end 
    
// -----------------------------------------------------------------------------
// xxxx.x Test Stimulus
// -----------------------------------------------------------------------------


// UDP Ethernet Packets
initial
    begin

        for (j = 0; j < 3; j = j + 1) begin    
            MONITOR_DATA    = 0;
            MONITOR_CLK     = 0;
            #(100 * ONE_US); //100us
            
            for (k = 0; k < 96; k = k + 1) begin
                if ((k < 8*j) | (k > 64 + (5*j)))
                    MONITOR_DATA    = 1;
                else    
                    MONITOR_DATA    = 0;
                    
                MONITOR_CLK     = ~MONITOR_CLK;
                # (MONITOR_PERIOD);
            end// k
        end// j
        
        #(9500 * ONE_US); //9500us
            
        MONITOR_DATA    = 1;
        MONITOR_CLK     = ~MONITOR_CLK;
        
        #ONE_MS;

    end
        
// Error Injection
initial
    begin
        for (j = 0; j<4; j = j + 1) begin
            SLIDE_SWITCH[5:4] = (j + 1);
            SLIDE_SWITCH[3:0] = (j + 1) * 2;
    
            PUSH_SWITCH[0] = 0;
            #1000;
            PUSH_SWITCH[0] = 1;
            #(30 * 1000000); //30ms
            PUSH_SWITCH[0] = 0;
            #(30 * 1000000); //30ms
        end
    end
     
// PRIME and ALIVE 
initial
    begin
        ALIVE[0] = 0;
        ALIVE[1] = 0;
        PRIME[0] = 0;
        PRIME[1] = 0;
        
        #ONE_MS;
        PRIME[0] = 1;
        #ONE_MS;
        
        for (i = 0; i <100; i = i + 1) begin
            # (ALIVE_PERIOD / 2);
            ALIVE[0] = !ALIVE[0];
        end
        
        ALIVE[0] = 0;
        ALIVE[1] = 0;
        PRIME[0] = 0;
        PRIME[1] = 0;
        
        #ONE_MS;
        PRIME[1] = 1;
        #ONE_MS;
        
        for (i = 0; i <100; i = i + 1) begin
            # (ALIVE_PERIOD / 2);
            ALIVE[1] = !ALIVE[1];
        end
        
        ALIVE[0] = 0;
        ALIVE[1] = 0;
        PRIME[0] = 0;
        PRIME[1] = 0;
        
    end


// INHIBIT
initial
    begin
        SLIDE_SWITCH[7] = 1;
        #(15 * ONE_MS); //15ms
        SLIDE_SWITCH[7] = 0;
    end 
    
    
// -----------------------------------------------------------------------------
// xxxx.x UUT Instantiation
// -----------------------------------------------------------------------------

BTE BTE_0 (

                // IN <-- UTILITY
                  .CLK                      (CLK)
                
                // IN <-- SWITCHES
                , .MONITOR_DATA             (MONITOR_DATA)
                , .MONITOR_CLK              (MONITOR_CLK)
                
                // IN <-- DEVICES
                , .PRIME                    (PRIME)
                , .ALIVE                    (ALIVE)
                
                // OUT --> DEVICES
                , .ERROR_TYPE_CONT_A        (ERROR_TYPE_CONT_A)
                , .ERROR_TYPE_CONT_B        (ERROR_TYPE_CONT_B)
                , .ERROR_TYPE_CONT_FDU      (ERROR_TYPE_CONT_FDU)
                
                // OUT --> COMPUTER
                , .SERIAL                   (SERIAL)
                
                // OUT --> ONBOARD DEBUG
                , .LED                      (LED)
                , .SEVEN_SEGMENT            (SEVEN_SEGMENT)
                , .SEVEN_SEGMENT_ANODE      (SEVEN_SEGMENT_ANODE)

                // IN <-- BOARD DEBUG
                , .SLIDE_SWITCH             (SLIDE_SWITCH)
                , .PUSH_SWITCH              (PUSH_SWITCH)                
                );
                
endmodule

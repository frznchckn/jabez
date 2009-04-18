`timescale 1ns / 1ps

`include "ssd.v"
`include "wdt.v"
`include "clk_cntr.v"

module fdu (
            input clk,
            input reset,
            input [2:0] fdu0,
            input [2:0] fdu1,
            input [1:0] error_sw,
            input [1:0] error_bte,
            inout 	usrs,
            output reg [1:0] prime,
            output [1:0]     prime_bte,
            output reg [2:0] state_led,
            output reg [1:0] prime_led,
            output reg [1:0] health,
            output [1:0]     por_out,
            output [7:0]     dac, 	     
            output [3:0]     an,
            output [6:0]     ssg);
   

   parameter DIV = 1;
   //use below value for simulation
   //   parameter DIV = 1000;

   //   parameter CLK_PRD = 40e-09;
   //TIMEOUT: String B cannot become PRIME in first 5 second unless String A loses PRIME
   //   parameter TIMEOUT = 5 / CLK_PRD / DIV;
   parameter TIMEOUT = 125000000;
   
   //   parameter POR_TERMINAL_COUNT = 0.5 / CLK_PRD / DIV;
   parameter POR_TERMINAL_COUNT = 12500000;
   //   parameter PING_TIMEOUT = 5 / CLK_PRD / DIV; //ping every 5s   
   parameter PING_TIMEOUT = 625000; //ping every 25ms

   //Do not use DIV for simulation here because that would be below CLK resolution
   //   parameter TRIGGER_PULSE = 5e-06 / CLK_PRD; //start pulse to ranger findger of 5us
   parameter TRIGGER_PULSE = 125; //start pulse to ranger findger of 5us
   parameter NO_PRIME = 3'b000;
   parameter PRIME_A = 3'b001;
   parameter PRIME_B = 3'b010;
   parameter UNHEALTHY = 1'b0;
   parameter HEALTHY = 1'b1;

   reg                       to_reached;
   reg [2:0]                 state;
   reg [2:0]                 next_state;
   reg [1:0]                 health_d1;
   reg [28:0]                por_count0;
   reg [28:0]                por_count1;
   wire [1:0]                health_int;

   reg [2:0]                 fdu0_tri;
   reg [2:0]                 fdu1_tri;
   
   reg [28:0]                to_count;
   reg [1:0]                 por;
   
   reg [32:0]                ping_count;
   reg                       pulsing;
   reg                       pulse;
   reg [31:0]                usrs_count;
   reg [31:0]                usrs_count_reduced;
   wire [1:0]                error_inject;
   reg [1:0]                 error_bte_d1;
   reg [1:0]                 error_bte_d2;
   reg [1:0]                 error_bte_d3;
   reg [1:0]                 error_bte_diff;

   wire                      ignore_bte;
   wire [1:0]                error_bte_d0;

   assign error_bte_d0[1:0] = ignore_bte ? error_bte[1:0] : 2'b00;
   
   assign dac[7:0] = usrs_count_reduced[15:8];
   
   assign por_out[0] = por[0] ? 1'b0 : 1'bz;
   assign por_out[1] = por[1] ? 1'b0 : 1'bz;

   assign usrs = (pulsing) ? pulse : 1'bz;
   assign prime_bte[1:0] = prime[1:0];

   
   assign error_inject[0] = error_sw[0] || error_bte_diff[0];
   assign error_inject[1] = error_sw[1] || error_bte_diff[1];

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             error_bte_diff[0] <= 0;
          end
        else if (error_bte_d2[0] && ~error_bte_d3[0])
          begin
             error_bte_diff[0] <= 1'b1;
          end
        else
          begin
             error_bte_diff[0] <= error_bte_diff[0];
          end
     end // always @ (posedge clk or posedge reset)
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             error_bte_diff[1] <= 0;
          end
        else if (error_bte_d2[1] && ~error_bte_d3[1])
          begin
             error_bte_diff[1] <= 1'b1;
          end
        else
          begin
             error_bte_diff[1] <= error_bte_diff[1];
          end
     end // always @ (posedge clk or posedge reset)
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             error_bte_d1 <= 2'b00;
             error_bte_d2 <= 2'b00;
             error_bte_d3 <= 2'b00;
          end
        else
          begin
             error_bte_d3 <= error_bte_d2;
             error_bte_d2 <= error_bte_d1;
             error_bte_d1 <= error_bte_d0;
          end
     end
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             usrs_count <= 0;
             usrs_count_reduced <= 0;
          end
        else if (ping_count == 0)
          begin
             usrs_count <= 0;
             usrs_count_reduced <= usrs_count_reduced;
          end
        else if ((ping_count > TRIGGER_PULSE) && (usrs))
          begin
             usrs_count <= usrs_count + 1;
             usrs_count_reduced <= usrs_count_reduced;
          end
        else if (ping_count == PING_TIMEOUT)
          begin
             usrs_count <= usrs_count;
             usrs_count_reduced <= usrs_count >> 4;
          end
        else
          begin
             usrs_count <= usrs_count;
             usrs_count_reduced <= usrs_count_reduced;
          end
     end
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             pulsing <= 1'b0;
             pulse <= 1'b0;
          end
        else if (ping_count < TRIGGER_PULSE)
          begin
             pulsing <= 1'b1;
             pulse <= 1'b1;
          end
        else if (ping_count == TRIGGER_PULSE)
          begin
             pulsing <= 1'b1;
             pulse <= 1'b0;
          end
        else
          begin
             pulsing <= 1'b0;
             pulse <= 1'b0;
          end
     end // always @ (posedge clk)
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             ping_count <= 0;
          end
        else if (ping_count < PING_TIMEOUT)
          begin
             ping_count <= ping_count + 1;
          end
        else
          begin
             ping_count <= 0;
          end
     end

   always @ (posedge clk)
     begin
        if (error_inject[0])
          begin
             fdu0_tri[2:0] <= 3'bzzz;
          end
        else
          begin
             fdu0_tri[2:0] <= fdu0[2:0];
          end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
        if (error_inject[1])
          begin
             fdu1_tri[2:0] <= 3'bzzz;
          end
        else
          begin
             fdu1_tri[2:0] <= fdu1[2:0];
          end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
        prime_led[1:0] <= ~prime[1:0];
     end

   always @ (posedge clk)
     begin
        state_led[2:0] <= state[2:0];
     end
   
   always @ (posedge clk)
     begin
        health_d1[0] <= health_int[0];
        health_d1[1] <= health_int[1];

        health[0] <= health_int[0];
        health[1] <= health_int[1];
     end

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             por_count0 <= 0;
          end
        else if (por[0])
          begin
             por_count0 <= por_count0 + 1;
          end
        else
          begin
             por_count0 <= 0;
          end
     end

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             por_count1 <= 0;
          end
        else if (por[1])
          begin
             por_count1 <= por_count1 + 1;
          end
        else
          begin
             por_count1 <= 0;
          end
     end
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             por[0] <= 1'b0;
          end
        else if (~health_int[0] && health_d1[0])
          begin
             por[0] <= 1'b1;
          end
        else if (por_count0 >= POR_TERMINAL_COUNT)
          begin
             por[0] <= 1'b0;
          end
        else
          begin
             por[0] <= por[0];
          end
     end // always @ (posedge clk or posedge reset )

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             por[1] <= 1'b0;
          end
        else if (~health_int[1] && health_d1[1])
          begin
             por[1] <= 1'b1;
          end
        else if (por_count1 >= POR_TERMINAL_COUNT)
          begin
             por[1] <= 1'b0;
          end
        else
          begin
             por[1] <= por[1];
          end
     end // always @ (posedge clk or posedge reset )
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             state <= NO_PRIME;
          end
        else
          begin
             state <= next_state;
          end
     end // always @ (posedge clk or posedge reset)
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             to_count <= 0;
             prime <= 2'b00;
             //             por <= 2'b00;
             to_reached <= 1'b0;
          end
        else 
          begin
             if (state == NO_PRIME)
               begin
                  prime <= 2'b00;
               end
             else if (state == PRIME_A)
               begin
                  prime <= 2'b01;
               end
             else if (state == PRIME_B)
               begin
                  prime <= 2'b10;
               end

             if (to_count <= TIMEOUT)
               to_count <= to_count + 1;
             else
               to_reached <= 1'b1;
          end
     end
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             next_state = NO_PRIME;
          end
        else
          begin

             next_state = state;
             
             case (state)
               
               NO_PRIME : begin
                  if (health[0] == HEALTHY)
                    begin
                       next_state = PRIME_A;
                    end
                  else if ((to_reached == 1'b1) && (health[1] == HEALTHY))
                    begin
                       next_state = PRIME_B;
                    end
                  else
                    begin
                       next_state = NO_PRIME;
                    end
               end // case: NO_PRIME

               PRIME_A : begin
                  if (health[0] == HEALTHY)
                    begin
                       next_state = PRIME_A;
                    end
                  else if (health[1] == HEALTHY)
                    begin
                       next_state = PRIME_B;
                    end
                  else
                    begin
                       next_state = NO_PRIME;
                    end
               end // case: PRIME_A
               
               PRIME_B : begin
                  if (health[1] == HEALTHY)
                    begin
                       next_state = PRIME_B;
                    end
                  else if (health[0] == HEALTHY)
                    begin
                       next_state = PRIME_A;
                    end
                  else
                    begin
                       next_state = NO_PRIME;
                    end
               end // case: PRIME_B

               default : begin
                  next_state = state;
               end

             endcase // case (state)
          end
        
     end // always @ (negedge clk)
   

   wdt wdt0 (clk,
             reset,
             fdu0_tri[2:0],
             health_int[0]
             );

   wdt wdt1 (clk,
             reset,
             fdu1_tri[2:0],
             health_int[1]
             );

   /*   display_value display_value0 (clk,
    reset,
    usrs_count_reduced,
    1'b1,
    an,
    ssg);
    */
   ssd display0 (clk,
                 reset,
                 1'b1,
                 usrs_count_reduced,
                 an,
                 ssg);

   clk_cntr #(
              .MAX_CNT(25000000),
              .ROLLOVER(1'b0)) clk_cntr0 (clk,
                                          reset,
                                          ignore_bte);
   
endmodule // fdu

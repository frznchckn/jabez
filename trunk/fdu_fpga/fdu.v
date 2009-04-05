`timescale 1ns / 1ps

module fdu (
            input clk,
            input reset,
            input [2:0] fdu0,
            input [2:0] fdu1,
            input [1:0] error,
            output reg [1:0] prime,
	    output reg [2:0] state_led,
            output reg [1:0] prime_led,
            output reg [1:0] health,
            output [1:0] por_out);
   


   parameter TIMEOUT = 250000000;
      //value to be used for simulation only!!!!
//   parameter TIMEOUT = 50000;

   parameter POR_TERMINAL_COUNT = 50000000;
      //value to be used for simulation only!!!!
//   parameter POR_TERMINAL_COUNT = 50000;


   
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

   reg [2:0]                fdu0_tri;
   reg [2:0]                fdu1_tri;
               
   reg [28:0]                to_count;
   reg [1:0] 		     por;
 		     

   assign por_out[0] = por[0] ? 1'b1 : 1'bz;
   assign por_out[1] = por[1] ? 1'b1 : 1'bz;
			
   always @ (posedge clk)
     begin
	if (error[0])
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
	if (error[1])
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
   
endmodule // fdu

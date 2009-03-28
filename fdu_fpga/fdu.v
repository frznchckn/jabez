module fdu (
            input clk,
            input reset,
            input [2:0] fdu0,
            input [2:0] fdu1,
            input [1:0] error,
            output reg [1:0] prime,
            output reg [1:0] por);
   
   wire [1:0]                health;

   reg [28:0]                to_count;

   parameter TIMEOUT = 250000000;

   //value to be used for simulation only!!!!
//   parameter TIMEOUT = 50000;
   
   parameter NO_PRIME = 3'b000;
   parameter PRIME_A = 3'b001;
   parameter PRIME_B = 3'b010;
   parameter UNHEALTHY = 1'b0;
   parameter HEALTHY = 1'b1;
   //   parameter THREE = 4'b0011;

   reg                       to_reached;
   reg [2:0]                 state;
   reg [2:0]                 next_state;
   
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             to_count <= 0;
             prime <= 2'b00;
             por <= 2'b00;
             to_reached <= 1'b0;
             state <= NO_PRIME;
          end
        else 
          begin

             state <= next_state;

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
   
   always @ (negedge health[0] or negedge health[1])
     begin
        
        por <= por;
        
        //        if ((to_count < TIMEOUT) )
        //          begin
        //          end
     end
   
   always @ (negedge clk)
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
          end

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
        
     end // always @ (negedge clk)
   

   wdt wdt0 (clk,
             reset,
             fdu0[2:0],
             health[0]
             );
   
   wdt wdt1 (clk,
             reset,
             fdu1[2:0],
             health[1]
             );
   
endmodule // fdu

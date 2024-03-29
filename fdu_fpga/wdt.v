module wdt (
            input clk,
            input reset,
            input [2:0] fdu,
            output reg health);
   
   reg [3:0]           state;
   reg [3:0]           next_state;

   //actual WDT count
   reg [23:0]          count;
   reg                 clear;
   reg [2:0] 	       fdu_d1;
   
   parameter TIMEOUT = 6500000;
   // this for sim
//   parameter TIMEOUT = 10000;
   
   parameter IDLE = 4'b1110;
   parameter ZERO = 4'b0000;
   parameter ONE = 4'b0001;
   parameter TWO = 4'b0010;
   parameter THREE = 4'b0011;
   parameter FOUR = 4'b0100;
   parameter FIVE = 4'b0101;
   parameter SIX = 4'b0110;
   parameter SEVEN = 4'b0111;
   parameter ERROR = 4'b1111;

   parameter UNHEALTHY = 1'b0;
   parameter HEALTHY = 1'b1;

   always @ (posedge clk)
     begin
	fdu_d1 <= fdu[2:0];
     end
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             count <= 0;
          end
        else if (clear)
          begin
             count <= 0;
          end
        else if (count < TIMEOUT)
          begin
             count <= count + 1;
          end
     end // always @ (posedge clk or posedge reset)

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             clear <= 1'b0;
          end
        else if ((next_state == SEVEN) && (state == SIX))
          begin
             clear <= 1'b1;
          end
        else if (count >= TIMEOUT)
          begin
             clear <= 1'b1;
          end
        else if (clear)
          begin
             clear <= 1'b0;
          end
     end // always @ (posedge clk or posedge reset)

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             health <= UNHEALTHY;
          end
        else if ((count >= TIMEOUT))
          begin
             health <= UNHEALTHY;
          end
        else if (state == SEVEN)
          begin
             health <= HEALTHY;
          end
        else if ((state == IDLE) || (state == ERROR))
          begin
             health <= UNHEALTHY;
          end
        else
          begin
             health <= health;
          end
     end // always @ (posedge clk or posedge reset)

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             state <= IDLE;
          end
        else if ((count >= TIMEOUT))
          begin
             state <= ERROR;
          end
        else
          begin
             state <= next_state;
          end
     end // always @ (posedge clk or posedge reset)

   always @ (posedge clk)
     begin
        if (count == TIMEOUT)
          begin
             next_state = IDLE;
          end
        else
          begin
             
             next_state = state;
             
             case (state)
  
               IDLE : begin
                  if (fdu_d1 == 3'b000)
                    begin
                       next_state = ZERO;
                    end
                  else
                    begin
                       next_state = IDLE;
                    end
               end

               ZERO : begin
                  if (fdu_d1 == 3'b000)
                    begin
                       next_state = ZERO;
                    end
                  else if (fdu_d1 == 3'b001)
                    begin
                       next_state = ONE;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end // case: ZERO
               
               ONE : begin
                  if (fdu_d1 == 3'b001)
                    begin
                       next_state = ONE;
                    end
                  else if (fdu_d1 == 3'b011)
                    begin
                       next_state = TWO;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end

               TWO : begin
                  if (fdu_d1 == 3'b011)
                    begin
                       next_state = TWO;
                    end
                  else if (fdu_d1 == 3'b010)
                    begin
                       next_state = THREE;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end

               THREE : begin
                  if (fdu_d1 == 3'b010)
                    begin
                       next_state = THREE;
                    end
                  else if (fdu_d1 == 3'b110)
                    begin
                       next_state = FOUR;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end

               FOUR : begin
                  if (fdu_d1 == 3'b110)
                    begin
                       next_state = FOUR;
                    end
                  else if (fdu_d1 == 3'b111)
                    begin
                       next_state = FIVE;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end

               FIVE : begin
                  if (fdu_d1 == 3'b111)
                    begin
                       next_state = FIVE;
                    end
                  else if  (fdu_d1 == 3'b101)
                    begin
                       next_state = SIX;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end
               

               SIX : begin
                  if (fdu_d1 == 3'b101)
                    begin
                       next_state = SIX;
                    end
                  else if (fdu_d1 == 3'b100)
                    begin
                       next_state = SEVEN;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end

               SEVEN : begin
                  if (fdu_d1 == 3'b100)
                    begin
                       next_state = SEVEN;
                    end
                  else if (fdu_d1 == 3'b000)
                    begin
                       next_state = ZERO;
                    end
                  else
                    begin
                       next_state = ERROR;
                    end
               end

               ERROR : begin
                  if (fdu_d1 == 3'b000)
                    begin
                       next_state = ZERO;
                    end
                  else
                    begin
                       next_state = IDLE;
                    end
               end

               default : begin
                  next_state = IDLE;
               end

             endcase
          end // else: !if(count = TIMEOUT)
        
     end // always @ (posedge clk)
   
   
endmodule

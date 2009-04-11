`timescale 1ns / 1ps

module ssd (
            input clk,
            input reset, 
            input activate,
            input [15:0] value,
            output reg [3:0] an,
            output reg [6:0] segments);
   

   reg [1:0]                 state;
   reg [1:0]                 next_state;
   reg [6:0]                 dig;
   reg [3:0]                 digit;
   reg [7:0]                 clkdiv;
   

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             clkdiv <= 0;
          end
        else
          begin
             clkdiv <= clkdiv + 1;
          end
     end
   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          segments <= 7'b1111111;   
        else
          segments <= ~dig;
     end

   always @ (posedge clkdiv[7] or posedge reset)
     begin
        if (reset)
          begin
             state <= 2'b00;
          end
        else
          begin
             state <= next_state;
          end
     end // always @ (posedge clk or posedge reset)


   
   always @(digit)
     begin
        case (digit)

          4'd0: dig =     7'b0111111;
          4'd1: dig =     7'b0000110;
          4'd2: dig =     7'b1011011;
          4'd3: dig =     7'b1001111;
          4'd4: dig =     7'b1100110;
          4'd5: dig =     7'b1101101;
          4'd6: dig =     7'b1111101;
          4'd7: dig =     7'b0000111;
          4'd8: dig =     7'b1111111;
          4'd9: dig =     7'b1101111;
          4'd10:  dig =     7'b1110111;
          4'd11:  dig =     7'b1111100;
          4'd12:  dig =     7'b0111001;
          4'd13:  dig =     7'b1011110;
          4'd14:  dig =     7'b1111001;
          4'd15:  dig =     7'b1110001;
          default: dig =    7'b0000000;
        endcase // case (digit)
        
     end // always @ (digit)

   //   assign next_state = clkdiv[7:6];
   
   always @ (activate or state or value)
     begin
        if (activate)
          begin
             case (state)
               
               2'b00 : begin
                  digit <= value[15:12];
                  an <= 4'b1110;
                  next_state <= 2'b01;
               end

               2'b01 : begin
                  digit <= value[11:8];     
                  an <= 4'b1101;
                  next_state <= 2'b10;
               end

               2'b10 : begin
                  digit <= value[7:4];      
                  an <= 4'b1011;
                  next_state <= 2'b11;
               end

               2'b11 : begin
                  digit <= value[3:0];      
                  an <= 4'b0111;
                  next_state <= 2'b00;
               end
             endcase // case (state)
             
          end // if (activate)
        else
          begin
             an <= 4'b1111;
             next_state <= 2'b00;
             //      segments <= 7'b1111111;
          end // else: !if(activate)
     end // always @ (activate or state or value)
   
endmodule // ssd







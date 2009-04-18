`timescale 1ns / 1ps

module clk_cntr (
                 input clk,
                 input reset,
                 output reg cnt_reached);
   
   parameter MAX_CNT = 10;
   parameter ROLLOVER = 1'b1;

   reg [31:0]               clk_cnt;
   
   always @ (posedge clk or posedge reset)
     begin
	    if (reset)
	      begin
	         clk_cnt <= 0;
	      end
	    else if (clk_cnt < MAX_CNT)
	      begin
	         clk_cnt <= clk_cnt + 1;
	      end
	    else if ((clk_cnt == MAX_CNT) && ROLLOVER)
	      begin
	         clk_cnt <= 0;
	      end
	    else
	      begin
	         clk_cnt <= clk_cnt;
	      end
     end // always @ (posedge clk or posedge reset)

   always @ (posedge clk or posedge reset)
     begin
        if (reset)
          begin
             cnt_reached <= 0;
          end
        else if (clk_cnt == MAX_CNT)
          begin
             cnt_reached <= 1'b1;
          end
        else if (clk_cnt == 1'b0)
          begin
             cnt_reached <= 1'b0;
          end
        else
          begin
             cnt_reached <= cnt_reached;
          end
     end
   
endmodule // clk_cntr


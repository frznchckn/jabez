`timescale 1ns / 1ps
`include "fdu.v"

module fdu_tb();
   // Declare inputs as regs and outputs as wires
   reg clk,  reset;
   reg [2:0] fdu0;
   reg [2:0] fdu1;
   reg [1:0] error;
   
   wire [1:0] prime;
   wire [1:0] por;

   // These are the grey code values, not to be confused with the state
   // definitions as in fdu.v
   parameter ZERO = 3'b000;
   parameter ONE = 3'b001;
   parameter TWO = 3'b011;
   parameter THREE = 3'b010;
   parameter FOUR = 3'b110;
   parameter FIVE = 3'b111;
   parameter SIX = 3'b101;
   parameter SEVEN = 3'b100;

   parameter MAKE = 20000;
   
   // Initialize all variables
   initial begin        
      //      $display ("time\t clk   reset   fdu   health");  
      //      $monitor ("%g\t %b   %b     %b     %b  ", 
      //                $time, clk, reset, fdu, health);
      $dumpfile("fdu_tb.vcd");
      $dumpvars(0, fdu_tb);

      clk = 0;       // initial value of clk
      #30
        reset = 1'b0;
      #2;
      reset = 1'b1;
      #2;
      reset = 1'b0;

      if (prime == 2'b00)
           $display("%g: PASS: prime should be 00", $time);
      else
           $display("%g: FAIL: prime should NOT be whatever it is", $time);
//VI ITEM
      $display("Verify only prime[0] can assert first during timeout period");     
      fdu1 = ZERO;
      #MAKE
        fdu1 = ONE;
      #MAKE
        fdu1 = TWO;
      #MAKE
      fdu1 = THREE;
      #MAKE
      fdu1 = FOUR;
      #MAKE
      fdu1 = FIVE;
      #MAKE
      fdu1 = SIX;
      #MAKE
      fdu1 = SEVEN;
      #MAKE
      fdu1 = ZERO;
      #MAKE
      if (prime == 2'b00)
           $display("%g: PASS: prime should be 00", $time);
      else
           $display("%g: FAIL: prime should NOT be whatever it is", $time);

      fdu0 = ZERO;
      fdu1 = ONE;
      #MAKE
        fdu0 = ONE;
      fdu1 = TWO;
      #MAKE
        fdu0 = TWO;
      fdu1 = THREE;
      #MAKE
      fdu0 = THREE;
      fdu1 = FOUR;
      #MAKE
        fdu0 = FOUR;
      fdu1 = FIVE;
      #MAKE
      fdu0 = FIVE;
      fdu1 = SIX;
      #MAKE
      fdu0 = SIX;
      fdu1 = SEVEN;
      #MAKE
      fdu0 = SEVEN;
      fdu1 = ZERO;
      #MAKE
      fdu0 = ZERO;
      fdu1 = ONE;
      #MAKE
      if (prime == 2'b01)
           $display("%g: PASS: prime should be 01", $time);
      else
           $display("%g: FAIL: prime should NOT be whatever it is", $time);
        
//VI ITEM
      $display("Verify only prime[1] can assert after prime[0] fails, still during timeout period");     
        fdu0 = TWO;
      #MAKE
      if (prime == 2'b10)
           $display("%g: PASS: prime should be 10", $time);
      else
           $display("%g: FAIL: prime should NOT be whatever it is", $time);
//VI ITEM
      $display("Verify  prime[1] deasserts properly");     
        fdu1 = SIX;
      #MAKE
      if (prime == 2'b00)
           $display("%g: PASS: prime should be 00", $time);
      else
           $display("%g: FAIL: prime should NOT be whatever it is", $time);

      wait(por[1] == 1'b0);
      #10000
//VI ITEM
//      $display("Verify POR1 assserts after B goes unhealthy");
//      fdu1 = FOUR;
//      #MAKE
        #200 $finish;      // Terminate simulation
      
   end

   
   // Clk generator
   always
     begin
        #20 clk = ~clk; // Toggle clk every 5 ticks
     end

   // Connect DUT to test bench
   
   fdu U_fdu (
              clk,
              reset,
              fdu0[2:0],
              fdu1[2:0],
              error[1:0],
              prime[1:0],
              por[1:0]);
endmodule

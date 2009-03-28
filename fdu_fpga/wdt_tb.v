`timescale 1ns / 1ps
`include "wdt.v"

module wdt_tb();
   // Declare inputs as regs and outputs as wires
   reg clk,  reset;
   reg [2:0] fdu;
   
   wire      health;

   // These are the grey code values, not to be confused with the state
   // definitions as in wdt.v
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
      $dumpfile("wdt_tb.vcd");
      $dumpvars(0, wdt_tb);

      clk = 0;       // initial value of clk
      #30
        reset = 1'b0;
      #2;
      reset = 1'b1;
      #2;
      reset = 1'b0;

      if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
      else
           $display("%g: FAIL: health should NOT be 1", $time);
//VI ITEM
      $display("Verify normal operation to assert health");     
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
//VI ITEM
      $display("Verify ZERO can go to ERROR");
      fdu = SEVEN;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
//VI ITEM
      $display("Verify ONE can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI ITEM
      $display("Verify TWO can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI ITEM
      $display("Verify THREE can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
//VI ITEM
      $display("Verify FOUR can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
//VI ITEM
      $display("Verify FIVE can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      
//VI ITEM
      $display("Verify SIX can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI ITEM
      $display("Verify SEVEN can go to ERROR");        
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
//VI
      $display("Verify that just getting to SEVEN does not trigger");        
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

//VI
      $display("Verify timeout from SEVEN");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from ZERO");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from ONE");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from TWO");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from THREE");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from FOUR");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from FIVE");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

//VI
      $display("Verify timeout from SIX");
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

      fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ZERO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = ONE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = TWO;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);

wait(health == 1'b0);
  if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
//VI ITEM
      $display("Verify recovery from timeout");     
      fdu = ZERO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);

        fdu = ONE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
        fdu = TWO;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = THREE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FOUR;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = FIVE;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SIX;
      #MAKE
        if (health == 1'b0)
           $display("%g: PASS: health should be 0", $time);
        else
           $display("%g: FAIL: health should NOT be 1", $time);
      fdu = SEVEN;
      #MAKE
        if (health == 1'b1)
           $display("%g: PASS: health should be 1", $time);
        else
           $display("%g: FAIL: health should NOT be 0", $time);


        #200 $finish;      // Terminate simulation
      
   end

   
   // Clk generator
   always
     begin
        #20 clk = ~clk; // Toggle clk every 5 ticks
     end

   // Connect DUT to test bench
   
   wdt U_wdt (
              clk,
              reset,
              fdu[2:0],
              health
              );
endmodule

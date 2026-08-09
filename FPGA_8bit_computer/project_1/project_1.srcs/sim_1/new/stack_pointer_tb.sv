`timescale 1ns / 1ps

module stack_pointer_tb;

    logic clk;
    logic reset;

    logic decrement_enable;
    logic increment_enable;

    logic [7:0] stack_address;


    stack_pointer dut (
        .clk              (clk),
        .reset            (reset),
        .decrement_enable (decrement_enable),
        .increment_enable (increment_enable),
        .stack_address    (stack_address)
    );


    // 10 ns clock period
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    initial begin

        // Safe starting values
        reset            = 1'b1;
        decrement_enable = 1'b0;
        increment_enable = 1'b0;

        // Hold reset for two clock cycles
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        #1;

 
        // TEST 1: Reset value
        
        if (stack_address !== 8'd239)
            $error("TEST 1 FAILED: SP should start at 239");
        else
            $display("TEST 1 PASSED: SP starts at 239");


        // TEST 2: Decrement once


        decrement_enable = 1'b1;

        @(posedge clk);
        #1;

        decrement_enable = 1'b0;

        if (stack_address !== 8'd238)
            $error("TEST 2 FAILED: SP should be 238");
        else
            $display("TEST 2 PASSED: SP decremented to 238");


   
        // TEST 3: Decrement again


        decrement_enable = 1'b1;

        @(posedge clk);
        #1;

        decrement_enable = 1'b0;

        if (stack_address !== 8'd237)
            $error("TEST 3 FAILED: SP should be 237");
        else
            $display("TEST 3 PASSED: SP decremented to 237");



        // TEST 4: Increment once


        increment_enable = 1'b1;

        @(posedge clk);
        #1;

        increment_enable = 1'b0;

        if (stack_address !== 8'd238)
            $error("TEST 4 FAILED: SP should be 238");
        else
            $display("TEST 4 PASSED: SP incremented to 238");


 
        // TEST 5: Increment again
 

        increment_enable = 1'b1;

        @(posedge clk);
        #1;

        increment_enable = 1'b0;

        if (stack_address !== 8'd239)
            $error("TEST 5 FAILED: SP should return to 239");
        else
            $display("TEST 5 PASSED: SP returned to 239");

        $display("STACK POINTER TESTING COMPLETE");

        $finish;

     end


    // Timeout protection
    initial begin

        #500;

        $error("Simulation timeout.");
        $finish;

    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 09:06:35 PM
// Design Name: 
// Module Name: program_counter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module program_counter_tb;

    logic           clk;
    logic           reset;
    logic           load_enable;
    logic           increment_enable;
    logic [7:0]    load_address;
    logic [7:0]    pc;

    program_counter dut (
        .clk              (clk),
        .reset            (reset),
        .load_enable      (load_enable),
        .increment_enable (increment_enable),
        .load_address     (load_address),
        .pc               (pc)
    );
    
    // 10 ns periods
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end
    
    initial begin
        reset            = 1'b0;
        load_enable      = 1'b0;
        increment_enable = 1'b0;
        load_address     = 8'h00;
        
        // =============== TEST 1 RESET =========================
        reset = 1'b1;
        // Wait one cycle
        @(posedge clk);
        #1;
        reset = 1'b0;
        
        // PC should now be 0000
        
        // ========== TEST 2 Increment Several Times ============
        increment_enable = 1'b1;
        // Wait 4 cycles
        repeat (4) begin
            @(posedge clk);
            #1;
        end
        increment_enable = 1'b0;
        
        // PC should be 0004
        
        // ================= TEST 3 HOLD =======================
        repeat (2) begin
            @(posedge clk);
            #1;
        end
        
        // PC should stay 0004
        
        // ================= TEST 4 LOAD ADDRESS ===============
        
        load_address = 8'd200;
        load_enable  = 1'b1;
        
        @(posedge clk);
        #1;
        
        load_enable = 1'b0;
        
        // PC should now equal 200;
        
        // ============== TEST 5 INCREMENT AFTER LOAD ============
        increment_enable = 1'b1;

        repeat (3) begin
            @(posedge clk);
            #1;
        end

        increment_enable = 1'b0;

        // PC should now equal 203
        
        // =========== TEST 6 LOAD PRIORITY OVER INCREMENT =========
        load_address     = 8'd5;
        load_enable      = 1'b1;
        increment_enable = 1'b1;
        
        @(posedge clk);
        #1;
        
        load_enable       = 1'b0;
        increment_enable  = 1'b0;
        
        // PC should be 5 not 204 or 6
        
        // =============== TEST 7 RESET PRIORITY =====================
        reset            = 1'b1;
        load_enable      = 1'b1;
        increment_enable = 1'b1;
        load_address     = 8'd255;

        @(posedge clk);
        #1;

        reset            = 1'b0;
        load_enable      = 1'b0;
        increment_enable = 1'b0;

        // PC should equal 0000

        // Give time to process
        repeat (2) begin
            @(posedge clk);
        end

        $finish; 
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 09:30:04 PM
// Design Name: 
// Module Name: datapath_tb
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


module datapath_tb;

    logic clk;
    logic reset;

    logic [2:0] source_a_addr;
    logic [2:0] source_b_addr;
    logic [2:0] destination_addr;

    logic [3:0] alu_operation;

    logic [7:0] external_data;
    logic       external_write_enable;
    logic       alu_write_enable;

    logic [7:0] source_a_data;
    logic [7:0] source_b_data;

    logic [7:0] alu_result;
    logic       zero;
    logic       carry;
    logic       negative;

    // Instantiate the combined datapath.
    datapath dut (
        .clk(clk),
        .reset(reset),

        .source_a_addr(source_a_addr),
        .source_b_addr(source_b_addr),
        .destination_addr(destination_addr),

        .alu_operation(alu_operation),

        .external_data(external_data),
        .external_write_enable(external_write_enable),
        .alu_write_enable(alu_write_enable),

        .source_a_data(source_a_data),
        .source_b_data(source_b_data),

        .alu_result(alu_result),
        .zero(zero),
        .carry(carry),
        .negative(negative)
    );
    
    // 100 MHz Simulation Clock:
    // full period is 10ns
    always #5 clk = ~clk;
    
    initial begin
    
        // Initial Values
        
        clk                   = 1'b0;
        reset                 = 1'b1;
        
        source_a_addr         = 3'd0;
        source_b_addr         = 3'd0;
        destination_addr      = 3'd0;
        
        alu_operation         = 4'h0;
        
        external_data         = 8'h00;
        external_write_enable = 1'b0;
        alu_write_enable      = 1'b0;
        
        // Keep reset active across at least one rising clock edge.
        #12;
        reset = 1'b0;
        
        // == == == LOAD R1 with 5 == == ==
        
        destination_addr      = 3'd1;
        external_data         = 8'd5;
        external_write_enable = 1'b1;
        
        // At the next rising edge R1 recieves 5.
        #10; 
        
        // == == == LOAD R2 with 3 == == ==
        
        destination_addr      = 3'd2;
        external_data         = 8'd3;
        external_write_enable = 1'b1;
        
        #10; 
        // Stop external writing 
        external_write_enable = 1'b0;
        
        
        // == == == SELECT R1 and R2 as ALU INPUTS == == ==
        
        source_a_addr       = 3'd1;
        source_b_addr       = 3'd2;
        
        // ADD TOGETHER
        alu_operation       = 4'd0;
        
        // Allow combinational outputs to process
        #10;
        
        // EXPECTED: 
        // source_a_addr = 5, source_b_addr = 3, alu_result = 8
        
        
        // == == == WRITE ALU RESULT back into R1 == == ==
        
        destination_addr     = 3'd1;
        alu_write_enable     = 1'b1;
        
        // next rising edge 
        // R1 = 8
        #10;
        
        alu_write_enable = 1'b0;
        
        // Confirm R1 now contains 8; 
        source_a_addr = 3'd1;
        source_b_addr = 3'd2;
        
        // EXPECTED:
        // source_a_addr = 8, source_b_addr = 3, alu_result = 11
        // ALU is still doing R1 + R2
        
        
        // == == == SUBTRACT R1 and R2 STORE INTO R3 == == ==
        
        alu_operation    = 4'h1;
        destination_addr = 3'd3;
        alu_write_enable = 1'b1;

        // R3 = R1 - R2 = 8 - 3 = 5
        #10;

        alu_write_enable = 1'b0;

        // Read R3 
        source_a_addr = 3'd3;
        source_b_addr = 3'd0;
        #10;

        // EXPECTED:
        // source_a_data = 5
        
        
        // == == == RESET ALL REGISTERS == == ==
        
        reset = 1'b1;
        #10;
        reset = 1'b0;
        
        source_a_addr = 3'd1;
        source_b_addr = 3'd2;
        #10;
        
        //EXPECTED:
        // All registers and alu_result set to 0;
        
        $finish;
     end
        
endmodule

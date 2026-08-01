`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2026 04:00:58 PM
// Design Name: 
// Module Name: alu_tb
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



// TESTBENCH ALU FILE
// used to simulate RTL design and does not run in hardware.
// TB files are used to feed inputs and analyze outputs to validate all cases.
module alu_tb;

    // Testbench signals (inputs diven into the ALU)
    logic [7:0] a;
    logic [7:0] b;
    logic [3:0] operation;
    
    // Observed outputs from the ALU (DUT)
    logic [7:0] result;
    logic       zero;
    logic       carry;
    logic       negative;
    
    // Instantiate the Device Under Test (DUT)
    // Connect TB-driven inputs to the ALU and monitor its outputs
    alu dut(
        .a(a),
        .b(b),
        .operation(operation),
        .result(result),
        .zero(zero),
        .carry(carry),
        .negative(negative)
    );
    
    initial begin
    
    // ADD 5 + 3 = 8
    a = 8'd5;
    b = 8'd3;
    operation = 4'h0;
    // wait 10 time units
    #10;
    
    // ADD with carry: 255 + 1 = 0 , carry = 1
    a = 8'hFF;
    b = 8'h01;
    operation = 4'h0;
    #10;
    
    // SUB 8 - 3 = 5
    a = 8'd8;
    b = 8'd3;
    operation = 4'h1;
    #10;
    
    // SUB with borrow: 3 - 8 = 251
    a = 8'd3;
    b = 8'd8;
    operation = 4'h1;
    #10;
    
    // AND
    a = 8'b1010_1100;
    b = 8'b1100_1010;
    operation = 4'h2;
    #10;
    
    // OR
    operation = 4'h3;
    #10;
    
    // XOR
    operation = 4'h4;
    #10;
    
    // NOT A
    operation = 4'h5;
    #10;
    
    // PASS A
    operation = 4'h6;
    #10;
    
    // PASS B 
    operation = 4'h7;
    #10;
    
    $finish;
    
  end
  
endmodule

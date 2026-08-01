`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2026 03:35:16 PM
// Design Name: 
// Module Name: instruction_memory_tb
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


module instruction_memory_tb;
    logic [7:0] address;
    logic [15:0] instruction;
    
    
instruction_memory dut(
    .address(address),
    .instruction(instruction)
);

// This Testbench checks that each address returns the correct 16-bit instruction loaded
// from program.mem these addresses will eventually be provided automatically by the 
// program counter.

    initial begin

        // Start at address 0.
        address = 8'd0;
        #10;

        // Address 0 should contain:
        // LOADI R1, 5
        if (instruction !== 16'b1001000100000101)
            $error(
                "Address 0 failed. Expected 1001000100000101, got %b",
                instruction
            );
        else
            $display(
                "Address 0 passed: LOADI R1, 5 = %b",
                instruction
            );

        // Address 1 should contain:
        // LOADI R2, 8
        address = 8'd1;
        #10;

        if (instruction !== 16'b1001001000001000)
            $error(
                "Address 1 failed. Expected 1001001000001000, got %b",
                instruction
            );
        else
            $display(
                "Address 1 passed: LOADI R2, 8 = %b",
                instruction
            );

        // Address 2 should contain:
        // ADD R3, R1, R2
        address = 8'd2;
        #10;

        if (instruction !== 16'b0000001100101000)
            $error(
                "Address 2 failed. Expected 0000001100101000, got %b",
                instruction
            );
        else
            $display(
                "Address 2 passed: ADD R3, R1, R2 = %b",
                instruction
            );

        // Address 3 should contain:
        // HALT
        address = 8'd3;
        #10;

        if (instruction !== 16'b1010100000000000)
            $error(
                "Address 3 failed. Expected 1010100000000000, got %b",
                instruction
            );
        else
            $display(
                "Address 3 passed: HALT = %b",
                instruction
            );

        $display("Instruction memory test completed.");

        $finish;

    end

endmodule

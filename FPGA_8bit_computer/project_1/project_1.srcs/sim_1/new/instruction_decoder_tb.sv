`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2026 10:36:24 PM
// Design Name: 
// Module Name: instruction_decoder_tb
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


module instruction_decoder_tb;
    logic [15:0] instruction;
    logic [4:0] opcode;
    logic [2:0] destination_addr;
    logic [2:0] source_a_addr;
    logic [2:0] source_b_addr;
    logic [7:0] address_or_immediate;
    logic [7:0] branch_address;
    
    instruction_decoder dut(
        .instruction(instruction),
        .opcode(opcode),
        .destination_addr(destination_addr),
        .source_a_addr(source_a_addr),
        .source_b_addr(source_b_addr),
        .address_or_immediate(address_or_immediate),
        .branch_address(branch_address)
    );
    
    
    initial begin
        //defaults
        instruction = 16'h0000;
        
        
    // ============== TEST 1 ADD R3, R1, R2 ====================
    // add R1 and R2 and store in R3
        instruction = 16'b00000_011_001_010_00;
        #10;
        
        if (opcode           !== 5'b00000 ||
            destination_addr !== 3'b011   ||
            source_a_addr    !== 3'b001   ||
            source_b_addr    !== 3'b010)
            $error("TEST 1 FAILED: ADD decoding incorrect");
        else
            $display("TEST 1 PASSED: ADD");
        
    // ============== TEST 2 NOT R4, R6 ========================
    // compute not R6 store in R4
        instruction = 16'b00101_100_110_00000;
        #10;
        
        if (opcode           !== 5'b00101 ||
            destination_addr !== 3'b100   ||
            source_a_addr    !== 3'b110)
            $error("TEST 2 FAILED: NOT decoding incorrect");
        else
            $display("TEST 2 PASSED: NOT");  
    
    // ============== TEST 3 JZ address 75 =====================
    // Jump to address 75
        instruction = 16'b01100_01001011_000;
        #10;
        
        if (opcode               !== 5'b01100 ||
            branch_address !== 8'd75)
            $error("TEST 3 FAILED: JZ decoding incorrect");
        else
            $display("TEST 3 PASSED: JZ");
        
    // =============== TEST 4 LOAD R2, address 75 ================
    // Load address 75 contents into R2
        instruction = 16'b10000_010_01001011;
        #10;
        
        if (opcode               !== 5'b10000 ||
            destination_addr     !== 3'b010   ||
            address_or_immediate !== 8'd75)
            $error("TEST 4 FAILED: LOAD decoding incorrect");
        else
            $display("TEST 4 PASSED: LOAD");
        
        
    // ============== TEST 5 LOADI R7, 200 ========================
    // Load immediate value "200" into R7
        instruction = 16'b10010_111_11001000;
        #10;
        
        if (opcode               !== 5'b10010 ||
            destination_addr     !== 3'b111   ||
            address_or_immediate !== 8'd200)
            $error("TEST 5 FAILED: LOADI decoding incorrect");
        else
            $display("TEST 5 PASSED: LOADI");
        
    // ============== TEST 6 HALT =================================
    // Halt the program
        instruction = 16'b10101_00000000000;
        #10;
        
        if (opcode !== 5'b10101)
            $error("TEST 6 FAILED: HALT decoding incorrect");
        else
            $display("TEST 6 PASSED: HALT");

        $display("Instruction decoder testing complete.");
        $finish;
    end

endmodule

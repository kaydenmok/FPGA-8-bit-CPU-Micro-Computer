`timescale 1ns / 1ps

// PROGRAM COUTER (PC) 
// The 8-bit program counter stores the address of the instruction 
// currently being executed.
//
// Its output is connected to Instruction Memory, allowing the CPU
// to fetch the instruction stored at that address.
//
// During normal execution, the PC increases so the CPU moves to the next instruction. 
// During a branch or jump, the PC may instead load a new address.
//
// The counter does not execute the instructions, it only fetches them from memory.
// This module will drive the instruction ROM. 

module program_counter(
    input logic         clk,
    input logic         reset,
    
    input logic         load_enable,
    input logic         increment_enable,
    
    input logic  [7:0] load_address,
    output logic [7:0] pc
    );
    
    always_ff @(posedge clk) begin
        // 1st priotity
        // reset the counter to 0
        if(reset) begin 
            pc <= 8'h00;
        end
        // 2nd priority
        // Jump to an address (ex: JMP 0x20)
        else if (load_enable) begin
            pc <= load_address;
        end
        // 3rd priority
        // When enables PC <= PC + 1
        else if (increment_enable) begin
            pc <= pc + 8'h01;
        end
        // 4th priority
        // If none of these are met the PC stays stationary
     end    
endmodule

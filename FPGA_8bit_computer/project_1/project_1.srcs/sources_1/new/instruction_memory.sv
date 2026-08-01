`timescale 1ns / 1ps
//
// INSTRUCTION MEMORY
// Instruction memory stores the program that the CPU executes.
// Acts like a Read-Only Memory (ROM), meaning the CPU can not modify
// the program during execution.
// 
// The program counter supplies a instruction address, and the memory
// outputs the 16-bit instruction stored at that location.
//
// Programs are assembled from human-readable assembly code into a binary .mem
// file using the Python assembler. At startup, this file is loaded into the
// instruction memory, allowing the CPU to fetch and execute 
// instructions sequentially. 
//
// EXAMPLE: 
// Instead of 00000_001_010_011_00 we can  
// directly write ADD R1, R2, R3

// =========================== FORMATTING =================================

// ADD   Rd, Ra, Rb
// SUB   Rd, Ra, Rb
// AND   Rd, Ra, Rb
// OR    Rd, Ra, Rb
// XOR   Rd, Ra, Rb

// NOT   Rd, Ra
// INC   Rd, Ra
// DEC   Rd, Ra
// SHL   Rd, Ra
// SHR   Rd, Ra

// MOV   Rd, Ra
// LOADI Rd, immediate

// LOAD  Rd, address
// STORE Rs, address

// JMP   address
// JZ    address
// JNZ   address
// JC    address
// JN    address

// NOP
// HALT
// ===========================================================================
//
// DIAGRAM:   PROGRAM COUNTER                             INSTRUCTION DECODER
//                    |                                            |
//          JMP Address (8bits) --> INSTRUCTION MEMORY --> 16-bit instruction
//                                                    
// Normal Execution: PC = PC + 1 (Next address)
// Branch Instruction: PC = Jump Address
// ============================================================================

module instruction_memory(
    // Address is 8 bits wide, allowing the PC to select one of 256 instruction locations
    // Each location stores a 16 bit instruction.
    // The ROM is 512 bytes total (Two bytes per instruction).
    input logic [7:0] address,
    output logic [15:0] instruction
    );
    
    // array of size 256 each storing a 16 bit instruction
    logic [15:0] memory [0:255];
    
    // Upon startup, copy the contents of program.mem into the memory array. 
    initial begin
        $readmemb("program.mem", memory);
    end
    
    // Program Counter selects which instruction is output.
    always_comb begin
        instruction = memory[address];
    end
    
endmodule

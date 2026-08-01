`timescale 1ns / 1ps

// INSTRUCTION DECODER
// Instruction Decoder separates a 16-bit instruction into its individual fields.
// 
// These fields may include
//   - Opcode
//   - Destination register
//   - Source register A
//   - Source register B
//   - Immediate value
//   - Memory address
//   - Branch address
//
// Different instruction formats exist because not every instruction requires the same information.
// For example: ADD requires three register addresses, while JMP oly requires a branch address.
//
// The decoder doesn't determine the active instruction format. It outputs every field it can 
// decode, and the control unit uses the opcode to decide which fields matter for that instruction.

module instruction_decoder(
    input logic [15:0] instruction,
    
    output logic [4:0] opcode,
    output logic [2:0] destination_addr,
    output logic [2:0] source_a_addr,
    output logic [2:0] source_b_addr,
    output logic [7:0] address_or_immediate,
    output logic [7:0] branch_address
    );
    
    
    // The opcode is stored in the upper five instruction bits.
    assign opcode = instruction[15:11];
    
    // These fields are useful for R-Type and U-Type instructions.
    assign destination_addr = instruction[10:8];
    
    // STORE has its own format where bits [10:8] are for source_a_addr
    // However, normally bits [7:5] are reserved for source_a_addr
    assign source_a_addr =
    (opcode == 5'b10001) ? instruction[10:8] : instruction[7:5];
    
    assign source_b_addr = instruction[4:2];
    
    // These lower eight bits are interpreted according to the opcode:
    // - memory address for LOAD and STORE
    // - immediate value for LOADI
    // - port number for IN and OUT
    assign address_or_immediate = instruction[7:0];
    
    // Branch Instruction store their target address in bits 
    assign branch_address = instruction[10:3];
endmodule

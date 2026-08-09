`timescale 1ns / 1ps

// Shared definitions for the CPU instruction set.
//
// A package lets multiple modules use the same opcode names.
// This prevents us from manually rewriting binary opcode values
// inside the decoder, control unit, testbenches, and other modules.
package isa_pkg;

    // Every instruction has its own unique 5-bit opcode.
    //
    // 5 bits gives us 32 possible instruction values:
    // 00000 through 11111.
    localparam logic [4:0]
        OP_ADD   = 5'b00000,
        OP_SUB   = 5'b00001,
        OP_AND   = 5'b00010,
        OP_OR    = 5'b00011,
        OP_XOR   = 5'b00100,

        OP_NOT   = 5'b00101,
        OP_INC   = 5'b00110,
        OP_DEC   = 5'b00111,
        OP_SHL   = 5'b01000,
        OP_SHR   = 5'b01001,
        OP_TEST  = 5'b01010,

        OP_JMP   = 5'b01011,
        OP_JZ    = 5'b01100,
        OP_JNZ   = 5'b01101,
        OP_JC    = 5'b01110,
        OP_JN    = 5'b01111,

        OP_LOAD  = 5'b10000,
        OP_STORE = 5'b10001,
        OP_LOADI = 5'b10010,
        OP_MOV   = 5'b10011,

        OP_NOP   = 5'b10100,
        OP_HALT  = 5'b10101,

        // Planned I/O instructions.
        // We can define them now even if their hardware is added later.
        OP_IN    = 5'b10110,
        OP_OUT   = 5'b10111,
        
        OP_PUSH  = 5'b11000,
        OP_POP   = 5'b11001,
        
        OP_CALL  = 5'b11010,
        OP_RET   = 5'b11011;

endpackage
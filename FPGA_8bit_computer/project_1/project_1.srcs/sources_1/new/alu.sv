`timescale 1ns / 1ps

// ARITHMETIC LOGIC UNIT (ALU)
// The ALU performs arithmetic and logic operations using values read from the register file.
//
// It recieves: One or Two operands and a operation code.
// Based on the selected operation it can perform calculations such as addition, subtraction, and 
// bitwise operations.
// 
// The ALU also produces the zero, carry, and negative flags, used for branch control.

module alu (
    // 8-bit operands for arithmetic and logic operations
    input  logic [7:0] a,
    input  logic [7:0] b,
    
    // 4-bit operation selector (opcode)
    // Determines what ALU function to perform (add, sub, or, etc)
    input  logic [3:0] operation,
    
    // 8-bit result of the selected ALU operation
    output logic [7:0] result,
    
    // Status flags:
    // zero     - asserted when result == 0
    // carry    - ADD: carry-out bit; SUB: no-borrow flag (a>=b)
    // negative - asserted when result's MSB is 1 (signed negative) 
    output logic       zero,
    output logic       carry,
    output logic       negative
);
    // localparam = cannot be local || logic = data type || [3:0] = vector size
    // Hexadecimal Opcode
    localparam logic [3:0]
        ALU_ADD     = 4'h0,
        ALU_SUB     = 4'h1,
        ALU_AND     = 4'h2,
        ALU_OR      = 4'h3,
        ALU_XOR     = 4'h4,
        ALU_NOT     = 4'h5,
        ALU_PASS_A  = 4'h6,
        ALU_INC     = 4'h7,
        ALU_DEC     = 4'h8,
        ALU_SHL     = 4'h9,
        ALU_SHR     = 4'hA;
        
    logic [8:0] extended_result;
    
    // always_comb = pure combinational logic.
    // Recomputes outputs immediately whenever any input changes (no clock involved).
    // Default assignments ensure every output is driven on every evaluation,
    // preventing unintended latches (which hold old values) and providing safe fallback values before case logic.
    always_comb begin
        result          = 8'h00;
        carry           = 1'b0;
        extended_result = 9'h000;
        
        // Instructions for each opcode
        case (operation)
            
            ALU_ADD: begin
                // 9-bit addition to preserve carry out
                extended_result = {1'b0, a} + {1'b0, b};
                // store the MSB as carry and the rest is stored as result
                result = extended_result[7:0];
                carry = extended_result[8];
            end
            
            ALU_SUB: begin
                result = a - b;

                // Borrow occurs when b > a (you can't subtract a smaller number from a larger one
                // without borrowing from the next higher bit).
                // carry = 1 means NO borrow, and carry = 0 means a borrow DID occur.
                carry = (a >= b);
            end
            
            ALU_AND: begin
                // result bits = 1 where both input bits are 1
                result = a & b;
            end
            
            ALU_OR: begin
                // result bits = 1 where either input bits is 1
                result = a | b;
            end
            
            ALU_XOR: begin
                // result bits = 1 where input bits are different
                result = a ^ b;
            end
            
            ALU_NOT: begin
                // results bits = flip each bit
                result = ~a;
            end
            
            ALU_PASS_A: begin
                result = a;
            end
            
            ALU_INC: begin
                // increment A (9 bits so overflow is carry)
                extended_result = {1'b0, a} + 1;
                carry  = extended_result[8];
                result = extended_result[7:0];
            end
            
            ALU_DEC: begin
                // decrement A
                result = a - 1;
                carry = (a >= 8'd1);
            end
            
            ALU_SHL: begin
                // shift everything one bit left
                // MSB is shifted into carry
                result = a << 1;
                carry = a[7];
            end
            
            ALU_SHR: begin
                // shift everything one bit right
                // old LSB is shifted into carry
                result = a >> 1;
                carry = a[0];
            end
            
            // set default values to 0
            default: begin
                result = 8'h00;
                carry  = 1'b0;
            end
        endcase
    end
    
    always_comb begin
        zero     = (result == 8'h00);
        negative = result[7];
    end
    
endmodule

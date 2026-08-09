`timescale 1ns / 1ps

// STACK POINTER
//
// The Stack Pointer stores the address of the current stack
// position inside Data RAM.
//
// The stack begins at address 239 and works downwards (238, 237 etc), 240 and up is reserved
// for memory mapping. 
//
// Since the stack grows downward:
// 
// PUSH:
//   Use the current SP (stack pointer) address
//   Then decrement SP
//
// POP:
//   Increment SP
//   Then use the updated address
//
// Follows a last-in First-out structure, meaning the most recently stored calue is the first
// one retrieved. It is commonly used to save return addresses during fuction calls.


module stack_pointer(
    input logic     clk,
    input logic     reset,
    
    // Move the stack pointer downward after PUSH
    input logic     decrement_enable,
    
    // Move the stack pointer upward before POP
    input logic     increment_enable,
    
    // Current stack address
    output logic [7:0] stack_address
    );
    
    always_ff @(posedge clk) begin
        
        if (reset) begin
            stack_address <= 8'd239;
        end
        
        else if (decrement_enable) begin
            stack_address <= stack_address - 8'd1;
        end
        
        else if (increment_enable) begin
            stack_address <= stack_address + 8'd1;
        end
     end
endmodule

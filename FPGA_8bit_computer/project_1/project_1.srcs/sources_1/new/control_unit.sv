`timescale 1ns / 1ps

// CONTROL UNIT
// The control unit determines what actions the CPU should perform. 
// 
// It recieves instruction opcode from the Instruction Decoder
// and converts it into control signals for the datapath and 
// other CPU components.
//
// For an ALU instruction such as ADD, the Control Unit may:
//      - Select the ADD operation for the ALU
//      - Enable writing to the register file
//      - Select the ALU result as the writeback value
//      - Disable branching
//      - Disable external or memory writeback
//
// The Control Unit does not perform calculations or move data itself. 
// It tells the datapath which actions are enabled for the current instruction.

module control_unit(
    input logic [4:0] opcode,
    
    // ALU flags used for conditional branching
    input logic       zero_flag,
    input logic       negative_flag,
    input logic       carry_flag,
    
    // Controls which operation the ALU performs
    output logic [3:0] alu_operation,
    
    // Enables writing a result into the register file.
    output logic       register_write_enable,
    
    // Selects what data is written into the destination register
    // 0 = ALU result    // 1 = external -> immediate or memory value
    output logic       writeback_external,
    
    // Tells the PC whether to load the branch address.
    output logic       branch_taken,
    
    // Allows arithmetic and logic instructions to update the stored flags.
    // Branch, memory, and immediate instructions should normally leave the existing flags unchanged.
    output logic       flag_write_enable,
    
    // Stops instruction execution after HALT
    output logic       halt,
    
    // Memory outputs
    output logic       memory_write_enable,
    output logic       memory_read_enable,
    
    // Stack outputs
    output logic       stack_decrement_enable,
    output logic       stack_increment_enable,
    output logic       stack_address_select,
    
    // Call and Return outputs
    output logic       call_enable,
    output logic       ret_enable
    );
    
    import isa_pkg::*;
    
    always_comb begin
        // Set safe defaults
        // Defaults are ran before the opcode below 
        // so signals are turned off after use.
        alu_operation           = 4'b0000;
        register_write_enable   = 1'b0;
        writeback_external      = 1'b0;
        branch_taken            = 1'b0;
        halt                    = 1'b0;
        memory_write_enable     = 1'b0;
        memory_read_enable      = 1'b0;
        flag_write_enable       = 1'b0;
        
        stack_address_select    = 1'b0;
        stack_decrement_enable  = 1'b0;
        stack_increment_enable  = 1'b0;
        
        call_enable             = 1'b0;
        ret_enable              = 1'b0;
        
        case (opcode)
            // The number is the associated ALU operation code
            // The instruction opcode can be found in "isa_pkg.sv"
            OP_ADD: begin // 0
                alu_operation         = 4'b0000;
                register_write_enable = 1'b1;
                flag_write_enable     = 1'b1;
            end
            
            OP_SUB: begin // 1
                alu_operation         = 4'b0001;
                register_write_enable = 1'b1;
                flag_write_enable     = 1'b1;
            end
            
            OP_AND: begin // 2
                alu_operation         = 4'b0010;
                register_write_enable = 1'b1;
                flag_write_enable     = 1'b1;
            end
            OP_OR: begin // 3
                alu_operation         = 4'b0011;
                register_write_enable = 1'b1;
                flag_write_enable     = 1'b1;
            end

            OP_XOR: begin // 4
                alu_operation         = 4'b0100;
                register_write_enable = 1'b1;
                flag_write_enable     = 1'b1;
            end

            OP_NOT: begin // 5
                alu_operation         = 4'b0101;
                register_write_enable = 1'b1;
                flag_write_enable     = 1'b1;
            end

            OP_INC: begin // 7
                alu_operation         = 4'b0111;
                register_write_enable = 1'b1;
            end

            OP_DEC: begin // 8
                alu_operation         = 4'b1000;
                register_write_enable = 1'b1;
            end

            OP_SHL: begin // 9
                alu_operation         = 4'b1001;
                register_write_enable = 1'b1;
            end

            OP_SHR: begin // 10
                alu_operation         = 4'b1010;
                register_write_enable = 1'b1;
            end
            
            OP_MOV: begin // 6 (Pass A in ALU)
                // PASS A sends Source A directly to destination
                alu_operation         = 4'b0110;
                register_write_enable = 1'b1;
            end
            
            OP_LOADI: begin 
                // Write the instruction's immediate value 
                register_write_enable = 1'b1;
                writeback_external    = 1'b1;
            end
            
            OP_JMP: begin 
                // PC <= PC + 1 when branch_taken = 0
                branch_taken = 1'b1;
            end
            
            OP_JZ: begin
                // JMP if zero flag
                branch_taken = zero_flag;
            end
            
            OP_JNZ: begin 
                // JMP if no zero flag
                branch_taken = ~zero_flag;
            end
            
            OP_JC: begin
                // JMP if carry flag
                branch_taken = carry_flag;
            end
            
            OP_JN: begin
                // JMP if negative flag
                branch_taken = negative_flag;
            end
            
            OP_NOP: begin
                // Do nothing
            end
            
            OP_HALT: begin 
                halt = 1'b1;
            end
            
            5'b10000: begin // LOAD
            // Read value from data memory and write into destination register
                register_write_enable = 1'b1;
                writeback_external   = 1'b1;
                
                memory_read_enable    = 1'b1;
                memory_write_enable   = 1'b0;
            end
            
            5'b10001: begin // STORE
            // Take a value from the register and store it into data memory
                register_write_enable = 1'b0;
                
                memory_read_enable    = 1'b0;
                memory_write_enable   = 1'b1;
            end
            
            5'b11000: begin // PUSH
            // PUSH reads a value from the selected source register
            // and stores it into Data RAM at the current Stack Pointer Address.
                register_write_enable = 1'b0;
                stack_decrement_enable= 1'b1;
                stack_address_select  = 1'b1;
                memory_write_enable   = 1'b1;
            end
            
            5'b11001: begin // POP
            // POP retrieves the most recently pushed value from the stack
            // and writes that value back into the selected destination register.
                register_write_enable = 1'b1;
                stack_increment_enable= 1'b1;
                stack_address_select  = 1'b1;
                memory_read_enable    = 1'b1;
                writeback_external    = 1'b1;
            end
            
            5'b11010: begin // CALL
            // CALL saves the return address onto the stack
                memory_write_enable   = 1'b1;
                stack_address_select  = 1'b1;
                // Pushing onto the stack: must decrement the pointer
                stack_decrement_enable= 1'b1;
                // CALL needs PC+1 written to RAM 
                call_enable           = 1'b1;
                // Jump to the function address
                branch_taken          = 1'b1;
                // CALL does not modify a register
                register_write_enable = 1'b0;
            end
            
            5'b11011: begin // RET
            // RET moves back to the location containing the saved returned address
                stack_increment_enable= 1'b1;
                stack_address_select  = 1'b1;
            
                // Read return address from RAM
                memory_read_enable    = 1'b1;
                // Tell PC to load the popped address.
                ret_enable            = 1'b1;
                register_write_enable = 1'b0;
            end
           
            
            
            default: begin
                // Unimplemented or invalid opcode
                // Do nothing safely
            end
        endcase
     end    
               
             
endmodule

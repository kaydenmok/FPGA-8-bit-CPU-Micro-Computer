`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 09:16:28 PM
// Design Name: 
// Module Name: control_unit_tb
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


module control_unit_tb;
    // Inputs
    logic [4:0] opcode;
    logic       zero_flag;
    logic       negative_flag;
    logic       carry_flag;
    
    // Outputs
    logic [3:0] alu_operation;
    logic       writeback_external;
    logic       register_write_enable;
    logic       branch_taken;
    logic       halt;
    
    // Memory control
    logic       memory_write_enable;
    logic       memory_read_enable;

    // Flag control
    logic       flag_write_enable;

    // Stack control
    logic       stack_address_select;
    logic       stack_decrement_enable;
    logic       stack_increment_enable;
    
    
    control_unit dut(
    .opcode                 (opcode),
    .zero_flag              (zero_flag),
    .negative_flag          (negative_flag),
    .carry_flag             (carry_flag),

    .alu_operation          (alu_operation),
    .register_write_enable  (register_write_enable),
    .writeback_external     (writeback_external),
    .branch_taken           (branch_taken),
    .halt                   (halt),

    .memory_write_enable    (memory_write_enable),
    .memory_read_enable     (memory_read_enable),

    .flag_write_enable      (flag_write_enable),

    .stack_address_select   (stack_address_select),
    .stack_decrement_enable (stack_decrement_enable),
    .stack_increment_enable (stack_increment_enable)
);
    initial begin
        
        // Safe start values
        opcode        = 5'b00000;
        zero_flag     = 1'b0;
        negative_flag = 1'b0;
        carry_flag    = 1'b0;
        #10;
        
        // ========== TEST 1 ADD ===========
        opcode = 5'b00000;
        #10;
        if(alu_operation         != 4'b0000 ||
           register_write_enable != 1'b1 ||
           writeback_external    !== 1'b0 ||
           branch_taken          !== 1'b0 ||
           halt                  !== 1'b0)
           $error("TEST 1 FAILED: ADD");
        else
           $display("TEST 1 PASSED: ADD");
            
        
        // ========== TEST 2 INC ===========
        opcode = 5'b00110;
        #10;

        if (alu_operation         !== 4'b0111 ||
            register_write_enable !== 1'b1    ||
            writeback_external    !== 1'b0    ||
            branch_taken          !== 1'b0    ||
            halt                  !== 1'b0)
            $error("TEST 2 FAILED: INC");
        else
            $display("TEST 2 PASSED: INC");
            
        // ========= TEST 3 MOV ============
        opcode = 5'b10011;
        #10;
        
        if (alu_operation         !== 4'b0110 ||
            register_write_enable !== 1'b1    ||
            writeback_external    !== 1'b0    ||
            branch_taken          !== 1'b0    ||
            halt                  !== 1'b0)
            $error("TEST 3 FAILED: MOV");
        else
            $display("TEST 3 PASSED: MOV");
        
        // ========== TEST 4 LOADI ==========
        opcode = 5'b10010;
        #10;

        if (register_write_enable !== 1'b1 ||
            writeback_external    !== 1'b1 ||
            branch_taken          !== 1'b0 ||
            halt                  !== 1'b0)
            $error("TEST 4 FAILED: LOADI");
        else
            $display("TEST 4 PASSED: LOADI");
            
        // =========== TEST 5 JMP ===========
        opcode = 5'b01011;
        #10;
        
        if (register_write_enable !== 1'b0 ||
            writeback_external    !== 1'b0 ||
            branch_taken          !== 1'b1 ||
            halt                  !== 1'b0)
            $error("TEST 5 FAILED: JMP");
        else
            $display("TEST 5 PASSED: JMP");
            
        // ======= TEST 6 JZ not taken ======
        opcode    = 5'b01100;
        zero_flag = 1'b0;
        #10;
        
        if (branch_taken !== 1'b0)
           $error("TEST 6 FAILED: JZ should not branch");
        else
            $display("TEST 6 PASSED: JZ not taken"); 
        
        // ======= TEST 7 JZ taken ==========
        opcode    = 5'b01100;
        zero_flag = 1'b1;
        #10;
        
        if (branch_taken !== 1'b1)
            $error("TEST 7 FAILED: JZ should branch");
        else
            $display("TEST 7 PASSED: JZ taken");
            
        // ====== TEST 8 JNZ taken ==========
        opcode    = 5'b01101;
        zero_flag = 1'b0;
        #10;

        if (branch_taken !== 1'b1)
            $error("TEST 8 FAILED: JNZ should branch");
        else
            $display("TEST 8 PASSED: JNZ taken");
            
       // ========= TEST 9 JC taken =========
       opcode     = 5'b01110;
       carry_flag = 1'b1;
       #10;

       if (branch_taken !== 1'b1)
           $error("TEST 9 FAILED: JC should branch");
       else
           $display("TEST 9 PASSED: JC taken");
           
           
       // ======== TEST 10 JN taken =========
       opcode        = 5'b01111;
       negative_flag = 1'b1;
       #10;
       
       if (branch_taken !== 1'b1)
           $error("TEST 10 FAILED: JN should branch");
       else
           $display("TEST 10 PASSED: JN taken");


        // Reset flags before non-branch tests.
        zero_flag     = 1'b0;
        carry_flag    = 1'b0;
        negative_flag = 1'b0;
        
        
        // ========= TEST 11 NOP ============
        opcode = 5'b10100;
        #10;

        if (register_write_enable !== 1'b0 ||
            writeback_external    !== 1'b0 ||
            branch_taken          !== 1'b0 ||
            halt                  !== 1'b0)
            $error("TEST 11 FAILED: NOP");
        else
            $display("TEST 11 PASSED: NOP");
        
        // ======== TEST 12 HALT ============
        opcode = 5'b10101;
        #10;

        if (register_write_enable !== 1'b0 ||
            branch_taken          !== 1'b0 ||
            halt                  !== 1'b1)
            $error("TEST 12 FAILED: HALT");
        else
            $display("TEST 12 PASSED: HALT");
            
        // ==== TEST 13 PUSH ====
        opcode = 5'b11000;
        #10;

        if (register_write_enable  !== 1'b0 ||
            writeback_external     !== 1'b0 ||
            memory_write_enable    !== 1'b1 ||
            memory_read_enable     !== 1'b0 ||
            stack_address_select   !== 1'b1 ||
            stack_decrement_enable !== 1'b1 ||
            stack_increment_enable !== 1'b0 ||
            branch_taken           !== 1'b0 ||
            halt                   !== 1'b0 ||
            flag_write_enable      !== 1'b0)
        
            $error("TEST 13 FAILED: PUSH control signals incorrect");

        else
            $display("TEST 13 PASSED: PUSH");
            
        // ==== TEST 14 POP ====
        opcode = 5'b11001;
        #10; 
        
        if (register_write_enable  !== 1'b1 ||
            writeback_external     !== 1'b1 ||
            memory_write_enable    !== 1'b0 ||
            memory_read_enable     !== 1'b1 ||
            stack_address_select   !== 1'b1 ||
            stack_increment_enable !== 1'b1 ||
            stack_decrement_enable !== 1'b0 ||
            branch_taken           !== 1'b0 ||
            halt                   !== 1'b0 ||
            flag_write_enable      !== 1'b0)

            $error("TEST 14 FAILED: POP control signals incorrect");

        else
            $display("TEST 14 PASSED: POP");


        $display("Control unit testing complete.");
         
        
       $finish;
     end

    
endmodule

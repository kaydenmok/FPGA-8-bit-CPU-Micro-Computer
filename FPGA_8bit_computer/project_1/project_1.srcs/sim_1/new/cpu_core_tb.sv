`timescale 1ns / 1ps

module cpu_core_tb;
    // Inputs and outputs of the cpu_core
    logic clk;
    logic reset;

    logic        halt;
    logic [7:0]  debug_pc;
    logic [15:0] debug_instruction;
    logic [7:0]  debug_alu_result;
    logic [7:0]  debug_source_a_data;
    logic [7:0]  debug_source_b_data;
    
    // Create one cpu_core called "dut" device under test
    // This generates the "box" holding all the modules that were
    // instantiated in cpu_core
    // We still need to put in our input (clk and reset) and output (debugs/halt)
    cpu_core dut (
        .clk                 (clk),
        .reset               (reset),

        .halt                (halt),
        .debug_pc            (debug_pc),
        .debug_instruction   (debug_instruction),
        .debug_alu_result    (debug_alu_result),
        .debug_source_a_data (debug_source_a_data),
        .debug_source_b_data (debug_source_b_data)
    );

    // Clock changes every 5ns --> full period 10ns
    initial begin
        clk = 1'b0;
        
        forever begin
            #5 clk = ~clk;
        end
    end
    
    // SETUP CHECK TASK
    // This prints PASS when a condition is correct
    // If incorrect the simulation stops with an error message
    task automatic check(
        input logic  condition,
        input string message
        );
        
        begin
            if (condition) begin
                $display("PASS: %s", message);
            end
            else begin
                $error("FAIL: %s", message);
                $finish;
            end
        end
    endtask
    
    // DISPLAY CPU ACTIVITY/IMPORTANT INFO WHENEVER THE CLOCK RISES 
    always @(posedge clk) begin
        if (!reset) begin
        /*
            $display(
                "Time=%0t | PC=%0d | Instruction=%b | A=%0d | B=%0d | ALU=%0d | HALT=%b",
                $time,
                debug_pc,
                debug_instruction,
                debug_source_a_data,
                debug_source_b_data,
                debug_alu_result,
                halt
            );
            */
         
            #1; // Wait for sequential logic to update

            $display(
            "PC=%0d | INST=%b | DEST=%0d | SRCA=%0d | A_DATA=%0d",
            debug_pc,
            debug_instruction,
            dut.destination_addr,
            dut.source_a_addr,
            debug_source_a_data
        );
        end
    end
    
// ============================================================
// TEST SEQUENCE
// ============================================================

/*
initial begin

    // Start with reset active.
    reset = 1'b1;

    // Hold reset for two clock cycles.
    repeat (2) @(posedge clk);

    // Release reset away from the rising edge.
    @(negedge clk);
    reset = 1'b0;

    #1;


    // --------------------------------------------------------
    // PC = 0
    // LOADI R1, 42
    // --------------------------------------------------------

    check(
        debug_pc == 8'd0,
        "PC starts at address 0"
    );

    check(
        dut.external_write_enable == 1'b1,
        "LOADI enables external writeback"
    );

    check(
        dut.alu_write_enable == 1'b0,
        "LOADI does not enable ALU writeback"
    );


    // Execute LOADI R1, 42
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // PC = 1
    // STORE R1, 20
    // --------------------------------------------------------

    check(
        debug_pc == 8'd1,
        "PC increments to address 1"
    );

    check(
        debug_source_a_data == 8'd42,
        "STORE reads value 42 from R1"
    );

    check(
        dut.memory_write_enable == 1'b1,
        "STORE enables data memory writing"
    );


    // Execute STORE R1, 20
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // Check RAM after STORE
    // --------------------------------------------------------

    check(
        dut.data_memory_unit.memory[20] == 8'd42,
        "STORE writes 42 into RAM address 20"
    );


    // --------------------------------------------------------
    // PC = 2
    // LOAD R2, 20
    // --------------------------------------------------------

    check(
        debug_pc == 8'd2,
        "PC increments to address 2"
    );

    check(
        dut.memory_read_data == 8'd42,
        "LOAD reads 42 from RAM address 20"
    );

    check(
        dut.memory_read_enable == 1'b1,
        "LOAD enables memory read mode"
    );

    check(
        dut.external_write_data == 8'd42,
        "RAM value is selected for register writeback"
    );

    check(
        dut.external_write_enable == 1'b1,
        "LOAD enables external register writeback"
    );


    // Execute LOAD R2, 20
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // PC = 3
    // ADD R3, R1, R2
    // --------------------------------------------------------

    check(
        debug_pc == 8'd3,
        "PC increments to address 3"
    );

    check(
        debug_source_a_data == 8'd42,
        "ADD reads 42 from R1"
    );

    check(
        debug_source_b_data == 8'd42,
        "ADD reads loaded value 42 from R2"
    );

    check(
        debug_alu_result == 8'd84,
        "ALU calculates 42 + 42 = 84"
    );

    check(
        dut.alu_write_enable == 1'b1,
        "ADD enables ALU writeback"
    );


    // Execute ADD R3, R1, R2
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // PC = 4
    // HALT
    // --------------------------------------------------------

    check(
        debug_pc == 8'd4,
        "PC increments to address 4"
    );

    check(
        halt == 1'b1,
        "HALT becomes active"
    );

    check(
        dut.pc_increment_enable == 1'b0,
        "HALT disables PC incrementing"
    );


    // Confirm that the PC stays frozen.
    repeat (3) @(posedge clk);
    #1;

    check(
        debug_pc == 8'd4,
        "PC remains at address 4 after HALT"
    );
    
    
    $finish;
 end
 
 
 // ================= STACK TESTS FOR PUSH AND POP =======================
    initial begin
        // Safe startup
        reset = 1'b1;

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        #1;
     
     // ==== PC = 0, LOADI R2, 42 ====
     check(
        debug_pc == 8'd0,
        "PC starts at address 0"
    );

    check(
        dut.external_write_enable == 1'b1,
        "LOADI enables register writeback"
    );


    // Execute LOADI
    @(posedge clk);
    #1;
    
    // ==== PC = 1, PUSH R1 ====
    check(
        debug_pc == 8'd1,
        "PC increments to PUSH instruction"
    );

    check(
        debug_source_a_data == 8'd42,
        "PUSH reads 42 from R1"
    );

    check(
        dut.stack_address == 8'd239,
        "Stack Pointer starts at 239"
    );

    check(
        dut.stack_address_select == 1'b1,
        "PUSH selects Stack Pointer as RAM address"
    );

    check(
        dut.memory_address == 8'd239,
        "RAM address comes from Stack Pointer"
    );

    check(
        dut.memory_write_enable == 1'b1,
        "PUSH enables memory writing"
    );

    check(
        dut.ram_write_enable == 1'b1,
        "PUSH enables Data RAM write"
    );


    // Execute PUSH
    @(posedge clk);
    #1;
    
    // VERIFY PUSH RESULT 
    check(
        dut.data_memory_unit.memory[239] == 8'd42,
        "PUSH stores 42 into RAM[239]"
    );

    check(
        dut.stack_address == 8'd238,
        "PUSH decrements Stack Pointer to 238"
    );
    
    // ==== PC = 2, LOAD R1, 0 ====
    // Clear the old value of R1 so POP can restore the original

    check(
        debug_pc == 8'd2,
        "PC increments to second LOADI instruction"
    );

    // Execute LOADI R1, 0
    @(posedge clk);
    #1;
    
    // Verify R1 was cleared
    check(
        debug_source_a_data == 8'd0,
        "R1 was cleared before POP"
    );
    
    // ==== PC = 3, POP R1 ====
    check(
        debug_pc == 8'd3,
        "PC increments to POP instruction"
    );

    check(
        dut.stack_address == 8'd238,
        "Stack Pointer is 238 before POP"
    );

    check(
        dut.stack_address_select == 1'b1,
        "POP selects Stack Pointer as RAM address"
    );

    check(
        dut.stack_increment_enable == 1'b1,
        "POP enables Stack Pointer increment"
    );

    check(
        dut.memory_read_enable == 1'b1,
        "POP enables memory reading"
    );

    check(
        dut.memory_write_enable == 1'b0,
        "POP does not write into RAM"
    );

    check(
        dut.register_write_enable == 1'b1,
        "POP enables destination register writing"
    );

    check(
        dut.writeback_external == 1'b1,
        "POP selects external/RAM writeback"
    );
    
    check(
        dut.memory_address == 8'd239,
        "POP reads from RAM address 239"
    );

    check(
        dut.memory_read_data == 8'd42,
        "POP receives 42 from RAM[239]"
    );

    check(
        dut.external_write_data == 8'd42,
        "POP routes RAM value 42 to register writeback"
    );

    check(
        dut.destination_addr == 3'd1,
        "POP selects R1 as destination register"
    );

    check(
        dut.external_write_enable == 1'b1,
        "POP enables external writeback into R1"
    );


    // Execute POP
    @(posedge clk);
    #1;
    
    // PC = 4
    // STORE R1, 20

    check(
        debug_pc == 8'd4,
        "PC increments to STORE instruction"
    );

    check(
        debug_source_a_data == 8'd42,
        "STORE reads restored value 42 from R1"
    );

    // Execute STORE
    @(posedge clk);
    #1;

    // Now verify RAM[20]
    check(
        dut.data_memory_unit.memory[20] == 8'd42,
        "POP successfully restored 42 into R1"
    );
    */
    // ============================================================
    // FULL CPU CALL + RET TEST
    // ============================================================

    initial begin

    // Safe startup
    reset = 1'b1;

    repeat (2) @(posedge clk);

    @(negedge clk);
    reset = 1'b0;

    #1;


    // --------------------------------------------------------
    // PC = 0
    // LOADI R1, 5
    // --------------------------------------------------------

    check(
        debug_pc == 8'd0,
        "PC starts at address 0"
    );

    check(
        dut.external_write_enable == 1'b1,
        "LOADI enables external register writeback"
    );

    // Execute LOADI R1, 5
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // PC = 1
    // CALL 5
    // --------------------------------------------------------

    check(
        debug_pc == 8'd1,
        "PC increments to CALL instruction"
    );

    check(
        dut.call_enable == 1'b1,
        "CALL enable becomes active"
    );

    check(
        dut.stack_address_select == 1'b1,
        "CALL selects Stack Pointer as RAM address"
    );

    check(
        dut.stack_decrement_enable == 1'b1,
        "CALL enables Stack Pointer decrement"
    );

    check(
        dut.memory_write_enable == 1'b1,
        "CALL enables RAM writing"
    );

    check(
        dut.memory_address == 8'd239,
        "CALL uses stack address 239"
    );

    check(
        dut.memory_write_data == 8'd2,
        "CALL prepares return address PC + 1"
    );


    // Execute CALL
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // VERIFY CALL RESULT
    // --------------------------------------------------------

    check(
        dut.data_memory_unit.memory[239] == 8'd2,
        "CALL stores return address 2 in RAM[239]"
    );

    check(
        dut.stack_address == 8'd238,
        "CALL decrements Stack Pointer to 238"
    );

    check(
        debug_pc == 8'd5,
        "CALL jumps to subroutine address 5"
    );


    // --------------------------------------------------------
    // PC = 5
    // INC R1, R1
    // --------------------------------------------------------

    check(
        debug_source_a_data == 8'd5,
        "INC reads value 5 from R1"
    );

    check(
        debug_alu_result == 8'd6,
        "INC calculates R1 + 1 = 6"
    );

    // Execute INC
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // PC = 6
    // RET
    // --------------------------------------------------------

    check(
        debug_pc == 8'd6,
        "PC increments to RET instruction"
    );

    check(
        dut.ret_enable == 1'b1,
        "RET enable becomes active"
    );

    check(
        dut.stack_address_select == 1'b1,
        "RET selects Stack Pointer as RAM address"
    );

    check(
        dut.stack_increment_enable == 1'b1,
        "RET enables Stack Pointer increment"
    );

    check(
        dut.memory_read_enable == 1'b1,
        "RET enables RAM reading"
    );

    check(
        dut.memory_address == 8'd239,
        "RET reads return address from RAM[239]"
    );

    check(
        dut.memory_read_data == 8'd2,
        "RET receives saved return address 2"
    );

    check(
        dut.pc_load_address == 8'd2,
        "RET routes saved return address to Program Counter"
    );


    // Execute RET
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // VERIFY RET RESULT
    // --------------------------------------------------------

    check(
        dut.stack_address == 8'd239,
        "RET increments Stack Pointer back to 239"
    );

    check(
        debug_pc == 8'd2,
        "RET returns execution to address 2"
    );


    // --------------------------------------------------------
    // PC = 2
    // LOADI R2, 20
    // --------------------------------------------------------

    check(
        dut.destination_addr == 3'd2,
        "LOADI selects R2 as destination"
    );

    // Execute LOADI R2, 20
    @(posedge clk);
    #1;


    // --------------------------------------------------------
    // PC = 3
    // HALT
    // --------------------------------------------------------

    check(
        debug_pc == 8'd3,
        "PC increments to HALT instruction"
    );

    check(
        halt == 1'b1,
        "HALT becomes active"
    );


    // --------------------------------------------------------
    // VERIFY FINAL CPU STATE
    // --------------------------------------------------------
    //
    // We use the datapath register file directly here because
    // R1 and R2 are not necessarily selected by the HALT
    // instruction's source fields.
    //
    // If your register array has a different internal name,
    // change "registers" below to match your register_file.sv.
    // --------------------------------------------------------

    check(
        dut.datapath_unit.register_file_instance.registers[1] == 8'd6,
        "Subroutine leaves R1 equal to 6"
    );

    check(
        dut.datapath_unit.register_file_instance.registers[2] == 8'd20,
        "Main program continues after RET and loads 20 into R2"
    );

    check(
        dut.stack_address == 8'd239,
        "Stack Pointer returns to starting address"
    );


    // Confirm HALT freezes the PC.
    repeat (3) @(posedge clk);
    #1;

    check(
        debug_pc == 8'd3,
        "PC remains frozen after HALT"
        );
    
    
    $finish;
end
        
    
     
     
     
     // TIME OUT PROTECTION
     // Stops the simulation if something prevents the normal test sequence from finishing
     // All initial blocks run at the same time
     // A limit of 500 ns is placed as the timeout error which forces end with $finish
     initial begin 
        #500;
        
        $error("simulation timeout: CPU did not finish correctly.");
        $finish;
     end
    
endmodule

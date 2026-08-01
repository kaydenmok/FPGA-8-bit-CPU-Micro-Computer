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

`timescale 1ns / 1ps

// This will act as the brain connecting all parts of the system in order to 
// properly implement it on the FPGA board 
//
// Program Counter, Instruction Memory + IO controller, Instruction Decoder, Control Unit, Datapath
//  
// Current Data Flow 
//
//
//
//  PC COUNTER -----> INSTRUCTION MEMORY
//                           |
//                    16-bit instruction
//                           |
//                           v
//                  INSTRUCTION DECODER
//                           |
//                  opcode + operands
//                     /           \
//                    v             v
//             CONTROL UNIT ----> DATAPATH
//                    |              |
//                    |              | <----> DATA MEMORY + MEMORY MAPPED IO
//                    |              |        LOAD / STORE
//                    |              |              +
//                    +---- control signals         |
//                                   |              |
//                                   v              |
//                            REGISTERS + ALU       |
//                                   |              |
//                                   v              |
//                            hardware output/input +
//
//
//
// The instruction decoder separates the instruction into:
//   - Opcode
//   - Destination Register
//   - Source Register A
//   - Source Register B
//   - Immediate / Address
//
// The Control Unit only cares about the opcode.
// It decides WHAT the CPU should do.
//
// The Datapath only cares about the operands.
// It moves data between the register file, ALU, and memory.
//
// The Control Unit sends control signals to the Datapath such as:
//   - ALU operation
//   - Register write enable
//   - Writeback source
//   - Branch taken
//   - HALT
//
// Together these allow the datapath hardware to perform the
// requested instruction.
//
// EXAMPLE: Instruction ADD R3, R1, R2
// Decoder outputs: Opcode = ADD, Destination = R3, Source A = R1, Source B = R2
// Datapath recieves: Desination = R3, Source A = R1, Source B = R2
// Control Unit recieves: Opcode = ADD
// Control Unit outputs: ALU Operation = ADD, Register Write ON, Branch OFF, External writeback OFF, halt OFF
// These signals are sent to DATAPATH and then to the hardware


// Module Signals are external and allow other modules to connect to it
module cpu_core(
    input logic         clk,
    input logic         reset,
    
    // FPGA inputs
    input logic [15:0]  switches,
    input logic [4:0]   buttons,
    
    // FPGA outputs
    output logic [15:0] leds,
    
    // Debug outputs make simulation and later board testing easier.
    output logic        halt,
    output logic [7:0]  debug_pc,
    output logic [15:0] debug_instruction,
    output logic [7:0]  debug_alu_result,
    output logic [7:0]  debug_source_a_data,
    output logic [7:0]  debug_source_b_data
   
    );
 
 // Outside Module, are internal and only this module can see them
 // Like private fields
 
    // ================ PROGRAM COUNTER AND INSTRUCTION FETCH SIGNALS ====================
    
    logic [7:0]  pc; // 8 bits wide address allowing 0 - 255
    logic [15:0] instruction; // Each instruction stored in memory is 16 bits
    logic        pc_increment_enable; // Allows PC to increment normally
    
    // ======================== INSTRUCTION DECODER SIGNALS ==============================
    
    logic [4:0] opcode; // The upper 5 bits of the instruction select the operation.
    // register and address select R0 through R7
    logic [2:0] destination_addr;
    logic [2:0] source_a_addr;
    logic [2:0] source_b_addr;
    
    logic [7:0] address_or_immediate; // Used for immediate values, memory addresses
    logic [7:0] branch_address; // Target address for jump and branch instructions
   
    
    // ============================ CONTROL UNIT SIGNALS =================================
    
    logic [3:0] alu_operation; // Tells the ALU which operation to perform
    logic       register_write_enable; // Controls register writing
    logic       writeback_external; // Controls source of data written into register
                                    // 0 = ALU result    1 = External/Immediate Data
    logic       branch_taken; // HIGH when a jump or conditional branch shoulld occur.
    
    // =============================== MEMORY SIGNALS =====================================
    
    logic [7:0] memory_read_data;
    logic       memory_write_enable;
    logic       memory_read_enable;
    logic [7:0] external_write_data;
    
    // ============================= IO CONTROLLER SIGNALS ================================
    
    logic       io_selected;
    logic [7:0] io_read_data;
   
    logic       ram_write_enable;
    logic       io_write_enable;
    
    
    
    // ========================== DATAPATH OUTPUT SIGNALS =================================
    
    // Data read from registers
    logic [7:0] source_a_data;
    logic [7:0] source_b_data;
    
    logic [7:0] alu_result; // Result produced by ALU
    
    // ALU flags
    logic       carry;
    logic       zero;
    logic       negative;
    
    // Control
    logic external_write_enable;
    logic alu_write_enable;
    
    // ========================== INTERAL CONNECTION LOGIC ===============================
    
    // During normal execution increment the PC.
    // DO NOT increment when:
    // 1. HALT is active OR 2. A branch is being taken
    //
    // When branch_taken is high, the PC loads branch_address instead
    
    assign pc_increment_enable = !halt && !branch_taken; 
    
    // Generate the datapath's two separate write-enable signals from the control unit
    // generate register-write signal
    //
    // Example:
    // LOADI -> write external/immediate data
    // ADD   -> write the ALU result
    
    assign external_write_enable  = register_write_enable && writeback_external;
    assign alu_write_enable       = register_write_enable && !writeback_external;
    
    // We have three possible ways to write data now
    // 1. Hardware input   2. LOADI    3. LOAD
    
    always_comb begin
        // Default value (LOADI)
        external_write_data = address_or_immediate;
        
        // if LOAD instruction
        if (memory_read_enable) begin
            // If address belongs to memory mapped I/O
            // Use the value coming from switches/buttons
            if(io_selected) begin
                external_write_data = io_read_data;
            end
            // Otherwise use memory data value
            else begin
                external_write_data = memory_read_data;
            end
        end
    end
    
    // Need to have signals to control when STORE goes to data memory or I/O
    assign ram_write_enable = memory_write_enable && !io_selected;
    assign io_write_enable  = memory_write_enable && io_selected; 
 
    // =============================== DEBUG OUTPUTS  ====================================
    
    // These outputs do not affect CPU operation, they expose useful internnal values 
    // for waveforms and later board displays.
    
     assign debug_pc = pc;
     assign debug_instruction = instruction;
     assign debug_alu_result = alu_result;
     assign debug_source_a_data = source_a_data;
     assign debug_source_b_data = source_b_data;
    
    // ============================ MODULE INSTANCES =====================================
    
    program_counter pc_unit (
        .clk                (clk),
        .reset              (reset),
        .load_enable        (branch_taken),
        .increment_enable   (pc_increment_enable),
        .load_address       (branch_address),
        .pc                 (pc)
    );
    
    instruction_memory instruction_memory_unit (
        .address    (pc),
        .instruction(instruction)
    );
    
    instruction_decoder decoder_unit(
        .instruction            (instruction),
        .opcode                 (opcode),
        .destination_addr       (destination_addr),
        .source_a_addr          (source_a_addr),
        .source_b_addr          (source_b_addr),

        .address_or_immediate   (address_or_immediate),
        .branch_address         (branch_address)
    );
    
    control_unit control_unit_instance (
        .opcode                (opcode),
        .zero_flag             (zero),
        .negative_flag         (negative),
        .carry_flag            (carry),

        .alu_operation         (alu_operation),
        .register_write_enable (register_write_enable),
        .writeback_external    (writeback_external),
        .branch_taken          (branch_taken),
        .halt                  (halt),
        .memory_write_enable   (memory_write_enable),
        .memory_read_enable    (memory_read_enable)
    );
    
    datapath datapath_unit (
        .clk                   (clk),
        .reset                 (reset),
        .source_a_addr         (source_a_addr),
        .source_b_addr         (source_b_addr),
        .destination_addr      (destination_addr),
        .alu_operation         (alu_operation),

        .external_data         (external_write_data),
        .external_write_enable (external_write_enable),
        .alu_write_enable      (alu_write_enable),

        .source_a_data         (source_a_data),
        .source_b_data         (source_b_data),
        
        .alu_result            (alu_result),
        .carry                 (carry),
        .zero                  (zero),
        .negative              (negative)
    );
    
    data_memory_file data_memory_unit (
        .clk          (clk),
    // LOAD and STORE use the instruction's 8-bit address field.
        .address      (address_or_immediate),
    // STORE writes the selected source register into RAM.
        .write_data   (source_a_data),

        .write_enable (ram_write_enable),
        
    // LOAD receives the value stored at the selected address.
        .read_data    (memory_read_data)
    );
    
    io_controller io_controller_unit (

    .clk          (clk),
    .reset        (reset),

    // Memory-mapped address being accessed.
    .address      (address_or_immediate),

    // STORE sends the selected register value to the I/O controller.
    .write_data   (source_a_data),

    // Only HIGH when STORE targets an I/O address.
    .write_enable (io_write_enable),

    // LOAD allows hardware values to be read.
    .read_enable  (memory_read_enable),

    // Physical FPGA inputs.
    .switches     (switches),
    .buttons      (buttons),

    // Physical FPGA output.
    .leds         (leds),

    // Data returned to CPU during an I/O LOAD.
    .read_data    (io_read_data),

    // HIGH when address is within the memory-mapped I/O region.
    .io_selected  (io_selected)

);
    
endmodule

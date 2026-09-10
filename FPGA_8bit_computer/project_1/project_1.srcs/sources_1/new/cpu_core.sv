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
    input logic [3:0]   buttons,
    
    // UART inputs
    input logic         uart_tx_busy,
    input logic [7:0]   uart_rx_data,
    input logic         uart_rx_valid,
   
    // UART outputs     
    output logic [7:0]  uart_tx_data,
    output logic        uart_tx_start,
    
    // FPGA outputs
    output logic [15:0] leds,
    
    // Seven Segment Display
    output logic [7:0]  display_value,
    output logic        display_mode,
    
    // Debug outputs make simulation and later board testing easier.
    output logic        halt,
    output logic [7:0]  debug_pc,
    output logic [15:0] debug_instruction,
    output logic [7:0]  debug_alu_result,
    output logic [7:0]  debug_source_a_data,
    output logic [7:0]  debug_source_b_data
   
    );
    
    // These registers preserve the result of the most recent instruction
    // that was allowed to update the CPU status flags.
    logic stored_zero_flag;
    logic stored_negative_flag;
    logic stored_carry_flag;
 
 // Outside Module, are internal and only this module can see them
 // Like private fields
 
    // ================ PROGRAM COUNTER AND INSTRUCTION FETCH SIGNALS ====================
    
    logic [7:0]  pc; // 8 bits wide address allowing 0 - 255
    logic [15:0] instruction; // Each instruction stored in memory is 16 bits
    logic        pc_increment_enable; // Allows PC to increment normally
    
    logic [7:0]  pc_load_address; // For RET address posibility
    logic        pc_load_enable;  
    
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
    logic       flag_write_enable; // HIGH when a flag is needed to be stored
    // =============================== MEMORY SIGNALS =====================================
    
    logic [7:0] memory_read_data;
    logic       memory_write_enable;
    logic       memory_read_enable;
    logic [7:0] external_write_data;
    
    logic [7:0] memory_write_data;
    
    logic       register_pointer_taken;
    
    logic       bank_write_enable;
    logic [1:0] bank_select;
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
    // The datapath produces temporary combinational flags for the
    // instruction currently passing through the ALU.
    logic       carry;
    logic       zero;
    logic       negative;
    
    // Control
    logic external_write_enable;
    logic alu_write_enable;
    
    // ========================== STACK POINTER SIGNALS ==================================
    
    logic [7:0] stack_address;
    logic [7:0] memory_address;
    
    logic       stack_increment_enable;
    logic       stack_decrement_enable;
    logic       stack_address_select;
    
    logic       call_enable;
    logic       ret_enable;
    
    // ========================== INTERAL CONNECTION LOGIC ===============================
    
    // During normal execution increment the PC.
    // DO NOT increment when:
    // 1. HALT is active OR 2. A branch is being taken
    //
    // When pc_load_enable is high, the PC loads the address instead
    
    assign pc_increment_enable = !halt && !pc_load_enable; 
    
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
    
    
    // Data RAM can be accessed in three ways:
    // 1. Normal instructions (LOAD/STORE), use the address encoded in the instruction
    // 2. Stack instructions (PUSH/POP), use the current Stack Pointer instead.
    // 3. Register pointer (LOADR), use the register value as a pointer to memory.
    
    // This multiplexer selects which address is sent to Data RAM
    // Additionally POP must take from the address: current stack pointer + 1 
    always_comb begin
        // Default: Use address in instruction
        memory_address = address_or_immediate;
        
        // Stack instruction access RAM using current stack pointer.
        if (stack_address_select) begin
            // PUSH uses current stack address
            if (stack_decrement_enable) begin
                memory_address = stack_address;
            end
            // POP uses the previously used stack location
            else if (stack_increment_enable) begin
                memory_address = stack_address + 8'd1;
            end
        end
        
        // Use the register value as a pointer to the memory
        else if (register_pointer_taken) begin
                memory_address = source_a_data;
        end
    end
    
    // Must increment PC when call is run so that the return goes to the next instruction
    always_comb begin
        // Normal STORE and PUSH write register data
        memory_write_data = source_a_data;
        
        // CALL stores the address of the instruction immediately
        // following CALL so RET knows where execution should resume.
        if(call_enable) begin
            memory_write_data = pc + 8'b1;
        end
    end
    
    // PC can recieve addresses in two ways.
    // 1. From JMP/Conditional Branching/CALL  --> branch_address
    // 2. From RET                             --> memory_read_data
    always_comb begin
        // Normal Branching and CALL
        pc_load_address = branch_address;
        if(ret_enable) begin
            pc_load_address = memory_read_data;
        end
    end
    // Jump to a address when branch_taken OR ret_enable are HIGH
    assign pc_load_enable = branch_taken || ret_enable;
    
    
    // BANKING 
    // If reset enable, set BANK to 0, otherwise, use the immediate bank value
    always_ff @(posedge clk) begin
        if (reset) begin 
            bank_select <= 2'b00;
        end
        else if (bank_write_enable) begin
            bank_select <= address_or_immediate[1:0];
        end
    end
    // =============================== DEBUG OUTPUTS  ====================================
    
    // These outputs do not affect CPU operation, they expose useful internnal values 
    // for waveforms and later board displays.
    
     assign debug_pc = pc;
     assign debug_instruction = instruction;
     assign debug_alu_result = alu_result;
     assign debug_source_a_data = source_a_data;
     assign debug_source_b_data = source_b_data;
     
    // ================================ FLAG LOGIC =======================================
    
    // Only update the stored CPU flags when flag_write_enable is active.
    // This prevents instructions that should not affect flags from overwriting them.
    always_ff @(posedge clk) begin
        if (reset) begin
            stored_zero_flag     <= 1'b0;
            stored_negative_flag <= 1'b0;
            stored_carry_flag    <= 1'b0;
        end
        else if (flag_write_enable) begin
            stored_zero_flag     <= zero;
            stored_negative_flag <= negative;
            stored_carry_flag    <= carry;
        end
    end          
    
    // ============================ MODULE INSTANCES =====================================
    
    program_counter pc_unit (
        .clk                (clk),
        .reset              (reset),
        .load_enable        (pc_load_enable),
        .increment_enable   (pc_increment_enable),
        .load_address       (pc_load_address),
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
        .zero_flag             (stored_zero_flag),
        .negative_flag         (stored_negative_flag),
        .carry_flag            (stored_carry_flag),

        .alu_operation         (alu_operation),
        .register_write_enable (register_write_enable),
        .flag_write_enable     (flag_write_enable),
        .writeback_external    (writeback_external),
        .branch_taken          (branch_taken),
        .halt                  (halt),
        .register_pointer_taken(register_pointer_taken),
        .memory_write_enable   (memory_write_enable),
        .memory_read_enable    (memory_read_enable),
        .stack_address_select  (stack_address_select),
        .stack_decrement_enable(stack_decrement_enable),
        .stack_increment_enable(stack_increment_enable),
        .bank_write_enable     (bank_write_enable),
        .call_enable           (call_enable),
        .ret_enable            (ret_enable)
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
        .address      (memory_address),
    // STORE writes the selected source register into RAM.
        .write_data   (memory_write_data),

        .write_enable (ram_write_enable),
        .bank_select  (bank_select),
        
    // LOAD receives the value stored at the selected address.
        .read_data    (memory_read_data)
    );
    
    io_controller io_controller_unit (

    .clk           (clk),
    .reset         (reset),

    // CPU memory-mapped access
    .address       (memory_address),
    .write_data    (source_a_data),
    .write_enable  (io_write_enable),
    .read_enable   (memory_read_enable),

    // FPGA inputs
    .switches      (switches),
    .buttons       (buttons),

    // UART inputs
    .uart_tx_busy  (uart_tx_busy),
    .uart_rx_data  (uart_rx_data),
    .uart_rx_valid (uart_rx_valid),

    // FPGA outputs
    .leds           (leds),

    // CPU readback
    .read_data      (io_read_data),
    .io_selected    (io_selected),

    // Seven-segment
    .display_value  (display_value),
    .display_mode   (display_mode),

    // UART outputs
    .uart_tx_data   (uart_tx_data),
    .uart_tx_start  (uart_tx_start)

    );

    stack_pointer stack_pointer_unit (
    .clk              (clk),
    .reset            (reset),
    .decrement_enable (stack_decrement_enable),
    .increment_enable (stack_increment_enable),
    .stack_address    (stack_address)
    );
    
endmodule

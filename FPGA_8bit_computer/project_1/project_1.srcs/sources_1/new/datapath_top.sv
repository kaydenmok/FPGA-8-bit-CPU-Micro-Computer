`timescale 1ns / 1ps

// The datapath is responsible for moving data between the register file,
// ALU, and memory (RAM). It does not decide what instruction is
// being executed; it simply performs the requested operation.
//
// Example:
//
// LOAD R2, Address
//
// The instruction decoder still produces values for Destination,
// Source A, and Source B because it always separates the instruction
// into the same fields.
//
// The Control Unit recognizes that this is a LOAD instruction and
// tells the datapath:
//
//     - Ignore Source A and Source B
//     - Read from memory
//     - Write the memory value into R2
//
// This allows one datapath to support many different instruction
// formats while the Control Unit determines which signals are used.
//
//The datapath always receives register fields, while the control unit decides which ones are needed.

module datapath_top(
    
    input logic         clk,
    input logic [15:0]  sw,
    
    input logic         btnC,
    input logic         btnU,
    input logic         btnD,
    input logic         btnL,
    input logic         btnR,
    
    output logic [15:0] led
    );
    
    // =============== SWITCH MAPPING ===================
    // Most right switch is sw0
    // SW7 - SW0 : External 8bit value to load a register
    // SW10-SW8  : Registor Selector (3bit for R0-7)
    // SW14-SW11 : Operation Selector for ALU
    // SW15      : ALU destination 
    //               - low  : Write result into source A
    //               - high : Write result into selected register 
    
    logic [7:0] external_data;
    logic [2:0] selected_register;
    logic [3:0] alu_operation;
    
    assign external_data    = sw[7:0];
    assign selected_register = sw[10:8];
    assign alu_operation     = sw[14:11];
    
    // =========== SOURCE REGISTER ADDRESSES ==============
    // Store the address of the selected register 
    // Decides what register to read 
    
    logic [2:0] source_a_addr;
    logic [2:0] source_b_addr;
    
    // =========== BUTTON SYNCHRONIZATION =================
    // The board buttons are physical signnals and are not
    // aligned with the FPGA clock.
    //
    // Each button must pass through two flip-flops (cycles) 
    // before being used by the design to reduce the chance
    // of metastability (cant decide between 0 or 1 on edge)
    // caused by a button changing near a clock edge.
    //
    // These synchronizers are not full button debouncers.
    // A real button debouncer is a small circuit that cleans
    // up messy/noisy button signals from physical buttons
    // If required they will be added later if problems occur.
    
    logic [1:0] btnC_sync; // Load external value into register
    logic [1:0] btnL_sync; // Save selected register as source A
    logic [1:0] btnR_sync; // Save selected register as source B
    logic [1:0] btnD_sync; // Execute and write ALU result
    
    always_ff @(posedge clk) begin
        if (btnU) begin // reset button
            btnC_sync <= 2'b00;
            btnL_sync <= 2'b00;
            btnR_sync <= 2'b00;
            btnD_sync <= 2'b00;
        end
        else begin
            // 2 flip flops ( 2bit ) to ensure metastability
            // Each cycle shift one flip flop, button sends signal
            // when both flip flops are high
            btnC_sync <= {btnC_sync[0], btnC};
            btnL_sync <= {btnL_sync[0], btnL};
            btnR_sync <= {btnR_sync[0], btnR};
            btnD_sync <= {btnD_sync[0], btnD};
        end
     end
     
     // ============ BUTTON EDGE DETECTION ==================
     // Holding a physical button could remain high for millions of cycles
     // We only want one action when the button changes from 0 -> 1
     //
     // Therefore we remember each button's previous value and create a one-clock
     // pulse on its rising edge.
     
     logic btnC_previous;
     logic btnL_previous;
     logic btnR_previous;
     logic btnD_previous;
     
     logic load_pulse;
     logic select_a_pulse;
     logic select_b_pulse;
     logic execute_pulse;
     
     always_ff @(posedge clk) begin
        if (btnU) begin
            btnC_previous <= 1'b0;
            btnL_previous <= 1'b0;
            btnR_previous <= 1'b0;
            btnD_previous <= 1'b0;
        end
        else begin
            btnC_previous <= btnC_sync[1];
            btnL_previous <= btnL_sync[1];
            btnR_previous <= btnR_sync[1];
            btnD_previous <= btnD_sync[1];
        end
     end
     
     // A pulse is high when the synchronized button is currently
     // high but its previous store value was low
     
     assign load_pulse      = btnC_sync[1] & ~btnC_previous;
     assign select_a_pulse  = btnL_sync[1] & ~btnL_previous;
     assign select_b_pulse  = btnR_sync[1] & ~btnR_previous;
     assign execute_pulse   = btnD_sync[1] & ~btnD_previous;
     
     // =========== SOURCE REGISTER SELECTION ===================
     // btnL saves current register as source A
     // btnR saves current register as source B
     // These addresses remain stored after the switches move
     
     always_ff @(posedge clk) begin 
        if (btnU) begin 
            source_a_addr <= 3'd0;
            source_b_addr <= 3'd0;
        end
        else begin
            if (select_a_pulse)
                source_a_addr <= selected_register;
            
            if (select_b_pulse)
                source_b_addr <= selected_register;    
        end
     end
     
     // =============== DESTINATION SELECTOR ====================
     // Two kinds of writes:
     // 1. External/Manual - btnC writes sw7-sw0 into selected register
     // 2. ALU write back  - btnD writes the ALU result
     //     During ALU write-back:
     //     SW15 LOW -> source A   |   SW15 HIGH -> selected register        
     
     logic [2:0] destination_addr;
     
     always_comb begin
        // Default destination
        destination_addr = selected_register;
        
        if (load_pulse) begin
            destination_addr = selected_register;
        end
        else if (execute_pulse) begin
            if (sw[15] == 1'b0)
                destination_addr = source_a_addr;
            else
                destination_addr = selected_register;
            end
        end
        
        // =============== DATAPATH OUTPUT SIGNALS =================
        
        logic [7:0] source_a_data;
        logic [7:0] source_b_data;
        
        logic [7:0] alu_result;
        logic       zero;
        logic       carry;
        logic       negative;
        
        
        // ================ DATAPATH INSTANCE ========================
        // The top level controls the datapath using switches and one
        // clock button pulses
        //
        // btnC pulse: external_write_enable = 1;
        // btnD pulse: alu_write_enable = 1;
        
        datapath datapath_instance (
            .clk                   (clk),
            .reset                  (btnU),
    
            .source_a_addr         (source_a_addr),
            .source_b_addr         (source_b_addr),
            .destination_addr      (destination_addr),

            .alu_operation         (alu_operation),
    
            .external_data         (external_data),
            .external_write_enable (load_pulse),
            .alu_write_enable      (execute_pulse),

            .source_a_data         (source_a_data),
            .source_b_data         (source_b_data),

            .alu_result            (alu_result),
            .zero                  (zero),
            .carry                 (carry),
            .negative              (negative)
        );
        
        // ====================== LED MAPPING ============================
        // Read from rightmost LED being LED0;
        // LED7-LED0  : Current ALU result
        // LED8       : Zero flag
        // LED9       : Carry flag or no-borrow flag
        // LED10      : Negative flag
        // LED13-LED11: Current Register
        // LED14      : Destination mode from SW15
        // LED15      : Raw execute button indicator (HIGH when btnD is HIGH)
        
        always_comb begin
            led = 16'h0000;
            led [7:0]  = alu_result;
            led [8]    = zero;
            led [9]    = carry;
            led [10]   = negative;
            
            led[13:11] = selected_register;
            led[14]    = sw[15];
            led[15]    = btnD;
            
         end
        
endmodule

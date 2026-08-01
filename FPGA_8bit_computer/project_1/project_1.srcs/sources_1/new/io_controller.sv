`timescale 1ns / 1ps

// I/O CONTROLLER
// This module handles memory-mapped input/output from the FPGA board
//
// The CPU uses the 8-bit address bus for both:
// 1. Normal RAM
// 2. Hardware peripherals
//
// The address determines what device the CPU is accessing
// 
// Memory map:
// 0x00 - 0xEF : Data RAM
//
// 0xF0 : LEDs 7-0
// 0xF1 : LEDs 15-8
//
// 0xF2 : Switches 7-0
// 0xF3 : Switches 15-8
//
// 0xF4 : Pushbuttons
//
// EXAMPLES:
// STORE R1, 0xF0 -----> LEDs 7-0 Shine the value of R1
//
// LOAD R1, 0xF2 ------> R1 gets value of switches 7-0


module io_controller(
    
    // CPU signals
    input logic        clk,
    input logic        reset,
    
    input logic [7:0]  address,
    input logic [7:0]  write_data,
    input logic        write_enable,
    input logic        read_enable,
    
    // Physical FPGA inputs
    input logic [15:0] switches,
    input logic [4:0]  buttons,
    
    // Physical FPGA outputs
    output logic [15:0] leds,
    
    // Data returned back to the CPU during LOAD
    output logic [7:0] read_data,
    
    // Tells the CPU whether this address belongs to I/O
    output logic       io_selected
    
    );
    
    // ========================== I/O ADDRESS DETECTION =============================
    // Any address from F0 (240) to FF (256) is consider I/O space
    // The first four bits of these addresses will always be 1111_XXXX
    // Therefore, we only need to check the upper four bits
    assign io_selected = (address[7:4] == 4'hF);
    
    // ============================= OUTPUT REGISTERS ================================
    // LEDS must remember the last value written by the CPU
    // This is why they use registers rather than simply being connected directly to write_data
    
    always_ff @(posedge clk) begin
        
        if (reset) begin
            leds <= 16'b0;
        end
        
        else if (write_enable && io_selected) begin
            
            case(address)
                
                // Bottom 8 LEDS
                8'hF0: begin
                    leds[7:0] <= write_data;
                end
                
                // Top 8 LEDS
                8'hF1: begin
                    leds[15:8] <= write_data;
                end
                
                // Reserved for future implementations
                default: begin
                    leds <= leds;
                end
            endcase
        end
    end
    
    // ============================= INPUT  REGISTERS ================================
    // Switches and Buttons already physically hold their state,
    // We do not need to stoe them in internal registers.
    //
    // The CPU reads whichever input corresponds to the current address
    
    always_comb begin
        
        // Default value if an unused I/O address is read.
        read_data = 8'b0;
        
        if (read_enable && io_selected) begin
        
            case(address)
                
                // Bottom 8 switches
                8'hF2: begin
                    read_data = switches[7:0];
                end
                
                // Top 8 switches
                8'hF3: begin
                    read_data = switches[15:8];
                end
                
                // Five buttons packed into the lower five bits.
                //
                // read_data[0] = center
                // read_data[1] = up
                // read_data[2] = down
                // read_data[3] = left
                // read_data[4] = right
                //
                // Upper three bits are unused                
                8'hF4: begin
                    read_data = {3'b000, buttons};
                end
                
                default: begin
                    read_data = 8'b0;
                end              
            endcase
         end
      end 
endmodule

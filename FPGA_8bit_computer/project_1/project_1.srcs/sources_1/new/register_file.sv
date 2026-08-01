`timescale 1ns / 1ps

// REGISTER FILE
// The register file contains eight general-purpose 8-bit registers: R0 through R7
// Registers are very fast but short term memory storage containers (reset on power off)
// 
// Two registers can be read at the same time, allowing datapath to provide two
// operands to the ALU
//
// One register can be written during a clock edge when the register write-enable
// control signal is active.
//
// The read addresses select which registers appear on the two read outputs.
// The destination address selects which register receives the writeback value.
//
// Control signals prevent register values from being changed unless the current instruction
// requires a register write.  


module register_file(
    // PORTS ==================================================
    input logic clk,
    input logic reset,
    
    // These two addresses choose which registers we want to read.
    // 3 bits can represent values 0 to 7, which is enough
    // to select one of eight registers: R0 through R7.
    input logic [2:0] read_addr_a,
    input logic [2:0] read_addr_b,
    
    // These signals control writing into one register 
    input logic [2:0] write_addr,
    input logic [7:0] write_data,
    input logic       write_enable,
    
    // The selected register values appear on these two outputs.
    output logic [7:0] read_data_a,
    output logic [7:0] read_data_b    
    );
    
    // This creates an array of eight registers.
    // Each register stores 8bits
    // registers[0] is R0, registers[3] is R3 etc
    logic [7:0] registers [0:7];
    
    // This interger is only used by the reset loop.
    // It lets us reset all 8 registers without writing eight statements
    integer i;
    
    // Sequential logic, must wait for clock edge to update
    always_ff @(posedge clk) begin
        if (reset) begin
            // Clear all registers to zero
            for (i = 0; i < 8; i = i + 1) begin
                // <= nonblocking assignment used inside clocked always_ff blocks
                // because all updates happen right at the clock edge.
                registers[i] <= 8'h00;
            end
        end
        
        // Only write when write_enable is high
        else if (write_enable) begin 
            // write_addr chooses what register gets write_data
            registers[write_addr] <= write_data;
        end
     end
     
     // Combinational logic, does not wait for clock edge
     always_comb begin
        // Asynchronous read ports.
        // read_addr_a and read_addr_b can independently select 
        // two registers at the same time.
        read_data_a = registers[read_addr_a];
        read_data_b = registers[read_addr_b];
     end
     
endmodule

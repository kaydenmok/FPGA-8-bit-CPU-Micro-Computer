`timescale 1ns / 1ps
// DATA MEMORY 
//
// This module stores normal program data.
// Unlike instructino memory, which stores 16-bit instructions,
// data memory stores 8-bit values because this is an 8-bit CPU.
//
// Address range:
// 0 - 255
//
// Each address stores:
// 8 bits
//
// Example:
// 
// memory[10] = 25
//
// If address = 10
// read_data will output 25
//
// Writing only happens on the rising edge of the clock when
// write_enable is HIGH.
//
// Reading is combinational, meaning read_data changes immediately when the
// address changes. 

module data_memory_file(
    input logic         clk,
    
    // Selects one of the 256 memory locations
    input logic [7:0]   address,
    
    // Value to store into memory
    input logic [7:0]   write_data,
    
    // HIGH = write write_data into memory[address].
    input logic         write_enable,
    
    // Value currently stored at memory[address].
    output logic [7:0]  read_data
    );
    
    // 256 locations each with an 8-bit value
    logic [7:0] memory [255:0];
    
    // ================ MEMORY READ ======================
    assign read_data = memory[address];
    
    // ================ MEMORY WRITE =====================
    always_ff @(posedge clk) begin
        
        if (write_enable) begin
            memory[address] <= write_data;
        end
    end 
    
    // ===================================================

endmodule

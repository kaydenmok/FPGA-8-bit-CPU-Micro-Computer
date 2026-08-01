`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 03:56:07 PM
// Design Name: 
// Module Name: datapath
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


module datapath(
    input logic        clk,
    input logic        reset,
    
    // Select which two registers for the ALU
    input logic [2:0]  source_a_addr,
    input logic [2:0]  source_b_addr,
    
    // Select the register that receives a new value.
    input logic [2:0]  destination_addr,
    
    // Controls which ALU operation is performed.
    input logic [3:0]  alu_operation,
    
    // External value used when manually loading registers (not a ALU result).
    input logic [7:0]  external_data,    
    
    // When high, write exteernal data into destination_addr
    input logic        external_write_enable,
    
    // When high, write the ALU result into destination_addr
    input logic        alu_write_enable,
    
    // Values currently being read from the register file.
    output logic [7:0] source_a_data,
    output logic [7:0] source_b_data,
    
    // Current ALU output and flags
    output logic [7:0] alu_result,
    output logic       carry,
    output logic       zero,
    output logic       negative 
    );
    
    // Internal logic declared outside port list
    // Wires are used to connect modules internally 
    // This is the value that will be sent to the register file
    logic [7:0] register_write_data;
    
    // Register file needs a write-enable single
    logic register_write_enable;
    
    // == == == WRITE BACK SELECTION == == ==
    // Multiplexer chooses what value gets written
    // In case both alu_write_enable and external_write_enable are both high:
    // External write is given priority.
    
    always_comb begin
        register_write_data   = 8'h00;
        register_write_enable = 1'b0;
        
        if (external_write_enable) begin
            register_write_data    = external_data;
            register_write_enable  = 1'b1;
        end
        else if (alu_write_enable) begin
            register_write_data    = alu_result;
            register_write_enable  = 1'b1;
        end
    end

    // == == == REGISTER FILE == == ==
    // Two registers can be read simultaneously
    // One register can be written on each rising clock edge
    // Connect the register file to datapath
    register_file register_file_instance (
        .clk(clk),
        .reset(reset),
        .read_addr_a(source_a_addr),
        .read_addr_b(source_b_addr),
        .write_addr(destination_addr),
        .write_data(register_write_data),
        .write_enable(register_write_enable),
        .read_data_a(source_a_data),
        .read_data_b(source_b_data)
    );
    // Connecting modules like this allow for encapsulation and protects internal signals
    
    // == == == ALU == == ==
    // Register file read outputs directly feed the ALU
    alu alu_instance (
        .a(source_a_data),
        .b(source_b_data),
        .operation(alu_operation),
        .result(alu_result),
        .zero(zero),
        .carry(carry),
        .negative(negative)
    );
   
endmodule
